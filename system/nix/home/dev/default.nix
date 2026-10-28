{
  inputs,
  osConfig,
  pkgs,
  ...
}: {
  imports = [
    ./bat.nix
    ./fish.nix
    ./ghostty.nix
    ./git.nix
    ./lsd.nix
    ./opencode.nix
  ];

  packages = with pkgs; [
    # Core
    gnumake
    man-pages
    man-pages-posix
    htop

    # Coding
    osConfig.rv.nvim
    osConfig.rv.editor
    codecrafters-cli

    # Virtualisation
    docker-compose

    # Local AI
    inputs.unsloth.packages.${pkgs.stdenv.hostPlatform.system}.unsloth-desktop
    inputs.unsloth.packages.${pkgs.stdenv.hostPlatform.system}.unsloth
  ];
}
