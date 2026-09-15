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
      ./obsidian.nix
      ./mpd.nix
      ./beets.nix
    ];

    home.packages = with pkgs; [
      # Core
      gnumake
      man-pages
      man-pages-posix

      # Coding
      config.rv.nvim
      config.rv.editor
      codecrafters-cli

      # Local AI
      (buildFHSEnv (
        unsloth-desktop.args
        // {
          # llama.cpp's Vulkan backend needs libvulkan.so.1, which neither
          # buildFHSEnv's base packages nor this derivation's targetPkgs
          # provide. The ICDs come from the host -- buildFHSEnv already puts
          # /run/opengl-driver/share on XDG_DATA_DIRS for exactly this.
          targetPkgs = pkgs:
            unsloth-desktop.args.targetPkgs pkgs
            ++ [
              pkgs.vulkan-loader
              pciutils
            ];

          profile =
            unsloth-desktop.args.profile
            + ''
              # WebKitGTK does HTTPS through libsoup3, which takes its TLS backend
              # from GIO, which only finds glib-networking via GIO_EXTRA_MODULES.
              # Neither the derivation's profile nor buildFHSEnv's generated
              # /etc/profile sets it, so every fetch from the webview -- the Model
              # hub tab -- fails as an opaque network error.
              export GIO_EXTRA_MODULES="/usr/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"

              # Keep the bootstrapped `uv` inside the preserved `~/.unsloth`
              # tree instead of `~/.local/bin`.
              export PATH="$UV_INSTALL_DIR''${PATH:+:$PATH}"
            '';
        }
      ))

      # Media
      nautilus
      loupe
      vlc
      euphonica

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
      wireshark
    ];

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "26.05";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
