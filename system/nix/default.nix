{...}: {
  imports = [
    ./disks
    ./ssh.nix
    ./audio.nix
    ./locale.nix
    ./user.nix
    ./preservation.nix
  ];
}
