{pkgs, ...}: {
  imports = [
    ./beets.nix
    ./mpd.nix
  ];

  packages = with pkgs; [
    euphonica
  ];
}
