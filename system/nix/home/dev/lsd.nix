{
  lib,
  pkgs,
  ...
}: {
  # Replaces home-manager's `programs.lsd`: installs lsd, writes the
  # catppuccin-latte colors.yaml plus the config.yaml HM auto-generates when a
  # custom color theme is set (`color.theme = "custom"`), and provides the fish
  # aliases (was programs.lsd.enableFishIntegration = true).
  packages = [pkgs.lsd];

  xdg.config.files = {
    "lsd/colors.yaml" = {
      generator = (pkgs.formats.yaml {}).generate "lsd-colors";
      value = {
        # https://github.com/catppuccin/lsd/blob/main/themes/catppuccin-latte/colors.yaml
        user = "#8839ef";
        group = "#7287fd";
        permission = {
          read = "#40a02b";
          write = "#df8e1d";
          exec = "#e64553";
          exec-sticky = "#8839ef";
          no-access = "#6c6f85";
          octal = "#179299";
          acl = "#179299";
          context = "#04a5e5";
        };
        date = {
          hour-old = "#179299";
          day-old = "#04a5e5";
          older = "#209fb5";
        };
        size = {
          none = "#6c6f85";
          small = "#40a02b";
          medium = "#df8e1d";
          large = "#fe640b";
        };
        inode = {
          valid = "#ea76cb";
          invalid = "#6c6f85";
        };
        links = {
          valid = "#ea76cb";
          invalid = "#6c6f85";
        };
        tree-edge = "#5c5f77";
        git-status = {
          default = "#4c4f69";
          unmodified = "#6c6f85";
          ignored = "#6c6f85";
          new-in-index = "#40a02b";
          new-in-workdir = "#40a02b";
          typechange = "#df8e1d";
          deleted = "#d20f39";
          renamed = "#40a02b";
          modified = "#df8e1d";
          conflicted = "#d20f39";
        };
      };
    };

    # HM auto-sets settings.color.theme = "custom" whenever `colors` is
    # non-empty, which makes it render lsd/config.yaml as well.
    "lsd/config.yaml" = {
      generator = (pkgs.formats.yaml {}).generate "lsd-config";
      value = {color.theme = "custom";};
    };

    # Rendered exactly as HM's fish module renders shellAliases:
    # `alias <name> <escapeShellArg value>` (sorted by name).
    "fish/conf.d/lsd.fish".text =
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: "alias ${k} ${lib.escapeShellArg v}") {
          ls = "${pkgs.lsd}/bin/lsd";
          ll = "${pkgs.lsd}/bin/lsd -l";
          la = "${pkgs.lsd}/bin/lsd -A";
          lt = "${pkgs.lsd}/bin/lsd --tree";
          lla = "${pkgs.lsd}/bin/lsd -lA";
          llt = "${pkgs.lsd}/bin/lsd -l --tree";
        }
      )
      + "\n";
  };
}
