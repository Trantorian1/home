{
  osConfig,
  unsloth,
  pkgs,
  ...
}: {
  imports = [
    ./bat.nix
    ./fish.nix
    ./ghostty.nix
    ./git.nix
    ./lsd.nix
  ];

  home.packages = with pkgs; [
    # Core
    gnumake
    man-pages
    man-pages-posix

    # Coding
    osConfig.rv.nvim
    osConfig.rv.editor
    codecrafters-cli

    # Virtualisation
    docker-compose

    # Local AI
    unsloth.packages.${pkgs.stdenv.hostPlatform.system}.unsloth-desktop
  ];
}
