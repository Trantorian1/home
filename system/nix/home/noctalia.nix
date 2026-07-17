{
  noctalia,
  osConfig,
  pkgs,
  ...
}: {
  imports = [noctalia.homeModules.default];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # Imperative nix version of `noctalia config export`
    settings = {
      # Disables startup greeter.
      # This needs to be set manually as we are using impermanence.
      shell.setup_wizard_enabled = false;

      # Disable all animations
      shell.animation.enabled = false;

      # Outer wilds wallpaper
      wallpaper.default.path = ../../../wallpaper.png;

      # A minimal bar showing only battery info on hover, hidden otherwise
      # Battery display is disabled if not on a laptop.
      bar = let
        common = {
          auto_hide = true;

          color = "on_surface";
          background_opacity = 0.0;
          margin_edge = 10;
          margin_ends = 0;
          reserve_space = false;
          shadow = false;

          capsule = true;
          capsule_fill = "surface";
          capsule_padding = 10.0;
        };
      in {
        order = [
          "default"
          "media"
        ];

        default =
          {
            enabled = osConfig.networking.hostName == "laptop";

            start = [];
            center = ["battery"];
            end = [];
          }
          // common;

        media = {
          enabled = true;
          position = "bottom";

          start = [];
          center = ["media"];
          end = [];
        };
      };

      theme = {
        # Automatic theming for applications built with GTK, Qt, and KDE Plasma
        # toolkits
        templates.builtin_ids = ["gtk4"];

        # Color scheme
        builtin = "Catppuccin";
        mode = "auto";
        pure_black_dark = true;

        wallpaper_scheme = "m3-content";
      };

      # See https://docs.noctalia.dev/v5/plugins/
      plugins = {
        enabled = ["noctalia/kaomoji"];

        source = [
          {
            name = "official";
            kind = "path";
            location = "${pkgs.fetchFromGitHub {
              owner = "noctalia-dev";
              repo = "official-plugins";
              rev = "24b3676fbc54e4b55657e14a8a1d645017564606";
              hash = "sha256-FqySr05EZeaLb2ETzYxjJ3zoXMk2bajsYuG+LbfbTjI=";
            }}";
          }
        ];
      };

      # Audio visualizer
      desktop_widgets = {
        schema_version = 2;
        widget_order = [
          "desktop-widget-0000000000000001"
          "desktop-widget-0000000000000002"
        ];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget = {
          desktop-widget-0000000000000001 = {
            type = "fancy_audio_visualizer";

            cx = 1280.0;
            cy = 720.0;

            box_height = 784.0;
            box_width = 736.0;

            settings = {
              background = false;
            };
          };

          desktop-widget-0000000000000002 = {
            type = "audio_visualizer";

            cx = 1280.0;
            cy = 720.0;

            box_height = 0.0;
            box_width = 0.0;

            settings = {
              background = false;
              show_when_idle = false;
              bands = 32;
            };
          };
        };
      };

      # A simple lockscreen with only a centered login bar
      lockscreen_widgets = {
        enabled = true;
        schema_version = 2;
        widget_order = ["lockscreen-login-box@HDMI-A-1"];

        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget = {
          "lockscreen-login-box@HDMI-A-1" = {
            box_height = 70.0;
            box_width = 400.0;
            cx = 1280.0;
            cy = 720.0;
            output = "HDMI-A-1";
            rotation = 0.0;
            type = "login_box";

            settings = {
              background_color = "surface_variant";
              background_opacity = 0.88;
              background_radius = 12.0;
              center_password_text = false;
              input_opacity = 1.0;
              input_radius = 6.0;
              show_caps_lock = true;
              show_keyboard_layout = false;
              show_login_button = false;
              show_password_hint = false;
            };
          };
        };
      };
    };
  };
}
