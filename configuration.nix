{
  pkgs,
  lib,
  ...
}: let
  sources = import ./npins;
  nixpkgs = import sources.nixpkgs {inherit (pkgs.stdenv.hostPlatform) system;};
in {
  imports = [
    ./nix/hardware.nix
    ./nix/audio.nix
    ./nix/gnome.nix
    ./nix/locale.nix
    ./nix/user.nix
    ./nix/disk.nix

    (sources.disko + "/module.nix")
  ];

  networking.hostName = "home";

  nix.settings.experimental-features = "nix-command flakes";

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
  nix.package = nixpkgs.lixPackageSets.stable.lix;

  # Pin the version of nixpkgs in use
  nix.registry.nixpkgs.flake = sources.nixpkgs;
  nix.nixPath = ["nixpkgs=flake:nixpkgs"];

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
}
