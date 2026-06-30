{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = [
      ./nix/hardware.nix
      ./nix/audio.nix
      ./nix/gnome.nix
      ./nix/locale.nix
      ./nix/user.nix
      ./nix/disk.nix

      inputs.disko.nixosModules.disko
    ];

    networking.hostName = "home";

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Override the nix version to use lix instead
    # https://git.lix.systems/lix-project/lix
    nixpkgs.overlays = [
      (final: prev: {
        inherit
          (prev.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      })
    ];
    nix.package = pkgs.lixPackageSets.stable.lix;

    # Default software in use by all users
    environment.systemPackages = with pkgs; [
      git
    ];

    # Use the grub boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.timeout = lib.mkForce 5;

    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;

    system.stateVersion = "26.05";
  };

  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.desktop];
  };

  flake.nixosConfigurations.home = self.nixosConfigurations.desktop;
}
