{...}: {
  imports = [
    ./disks
    ./audio.nix
    ./locale.nix
    ./sops.nix
    ./user.nix
    ./preservation.nix
    ./virtualisation.nix
  ];
}
