{pkgs, ...}: {
  imports = [
    ./beets.nix
    ./mpd.nix
  ];

  home.packages = with pkgs; [
    euphonica
  ];
}
