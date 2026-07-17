{config, ...}: {
  # By default, home-manager does not use the global nixpkgs, even when
  # `inputs.nixpkgs.follows` is set. This can pose issues when sharing package
  # overlays between system and home installations, so we disable that behavior.
  home-manager.useGlobalPkgs = true;

  # Home-manager will not overwrite existing user configuration files. This sets
  # the  default backup extension to use so home-manager can make a copy of any
  # such file during system installation.
  home-manager.backupFileExtension = "bak";

  # Home-manager does NOT create the `dev` user, it only configures it. Any
  # system-wide user settings need to be specified in `user.nix` instead.
  home-manager.users.dev = {pkgs, ...}: {
    imports = [
      ./niri
      ./zen-browser
      ./noctalia.nix
      ./ghostty.nix
      ./fish.nix
      ./lsd.nix
      ./git.nix
      ./obs.nix
      ./bat.nix
      ./ssh.nix
    ];

    home.packages = with pkgs; [
      config.rv.nvim
      config.rv.editor

      gnumake
      nautilus

      protonmail-desktop
      discord

      typora
      inkscape
      gimp

      vlc
      sioyek
    ];

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "26.05";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
