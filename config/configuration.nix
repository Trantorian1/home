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

  # Include configuration into the finished system
  systemd.tmpfiles.rules = [
    "C /etc/nixos 644 root root - ${./.}"
    "Z /etc/nixos 644 root root"
  ];

  system.stateVersion = "26.05";
}
