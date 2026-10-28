{pkgs, ...}: {
  # Hjem does NOT create the `dev` user, it only configures it. Any
  # system-wide user settings need to be specified in `user.nix` instead.
  hjem.users.dev = {
    directory = "/home/dev";

    # Overwrite files managed by Hjem on rebuild (impermanence friendly).
    clobberFiles = true;

    imports = [
      ./niri
      ./zen-browser
      ./dev
      ./audio

      ./noctalia.nix
      ./obs.nix
      ./ssh.nix
      ./obsidian.nix
    ];

    packages = with pkgs; [
      # Media
      nautilus
      grayjay
      loupe
      vlc
      inkscape

      # Writing
      typora
      sioyek

      # Visual editing
      inkscape
      gimp

      # User apps
      protonmail-desktop
      discord
      bambu-studio
    ];
  };
}
