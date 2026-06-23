{
  pkgs,
  lib,
  ...
}: let
  sources = import ./npins;
  nixpkgs = import sources.nixpkgs {inherit (pkgs.stdenv.hostPlatform) system;};
in {
  imports = [
    ./nix/audio.nix
    ./nix/gnome.nix
    ./nix/locale.nix
    ./nix/user.nix
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

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = lib.mkForce 5;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Include configuration into the finished system
  systemd.tmpfiles.rules = [
    "C /etc/nixos 644 root root - ${./.}"
    "Z /etc/nixos 644 root root"
  ];

  system.stateVersion = "26.05";
}
