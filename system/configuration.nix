{inputs, ...}: {
  imports = [./hosts];

  flake.nixosModules.core = {
    config,
    pkgs,
    lib,
    ...
  }: {
    imports = [
      ./nix

      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.rv.nixosModules.default
    ];

    home-manager.sharedModules = [inputs.sops-nix.homeManagerModules.sops];
    home-manager.extraSpecialArgs = {inherit (inputs) zen-browser noctalia;};

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

    # Use the grub boot loader.
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.timeout = lib.mkForce 5;

    boot.zfs.forceImportRoot = false;

    # Configure network connections interactively with nmcli or nmtui.
    networking.networkmanager.enable = true;

    # Used by noctalia
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";
  };
}
