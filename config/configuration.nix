{lib, ...}: {
  imports = [
    ./nix/audio.nix
    ./nix/gnome.nix
    ./nix/locale.nix
    ./nix/user.nix
  ];

  networking.hostName = "home";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = lib.mkForce 5;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  system.stateVersion = "26.05";
}
