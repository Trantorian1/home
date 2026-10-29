{
  config,
  inputs,
  pkgs,
  ...
}: {
  hjem.specialArgs = {inherit inputs;};

  hjem.users.dev = {
    directory = config.users.users.dev.home;

    clobberFiles = true;

    imports = [
      ./niri
      ./zen-browser
      ./dev
      ./audio

      ./noctalia.nix
      ./obs.nix
      ./ssh.nix
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
      obsidian

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
