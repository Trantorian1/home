{...}: {
  imports = [
    ./docker.nix
    ./disks
    ./audio.nix
    ./locale.nix
    ./user.nix
    ./preservation.nix
  ];
}
