{...}: {
  imports = [
    ./disks
    ./ssh.nix
    ./audio.nix
    ./gnome.nix
    ./locale.nix
    ./user.nix
    ./preservation.nix
  ];
}
