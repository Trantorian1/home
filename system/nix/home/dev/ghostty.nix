{
  config,
  lib,
  pkgs,
  ...
}: {
  # Replaces home-manager's `programs.ghostty`: installs ghostty, renders the
  # XDG config with HM's exact keyValue format (lists become duplicate keys),
  # and links the systemd app service + drop-in and D-Bus service file that
  # HM linked by default on Linux (`programs.ghostty.systemd`).
  packages = [pkgs.ghostty];

  xdg.config.files = {
    "ghostty/config" = {
      generator = (
        pkgs.formats.keyValue {
          listsAsDuplicateKeys = true;
          mkKeyValue = lib.generators.mkKeyValueDefault {} " = ";
        }
      ).generate "ghostty-config";
      value = {
        shell-integration = "fish";
        cursor-style = "bar";
        keybind = [
          # Navigate splits
          "alt+left=goto_split:left"
          "alt+right=goto_split:right"
          "alt+down=goto_split:down"
          "alt+up=goto_split:up"

          # New splits
          "alt+shift+left=new_split:left"
          "alt+shift+right=new_split:right"
          "alt+shift+down=new_split:down"
          "alt+shift+up=new_split:up"
        ];
      };
    };

    "systemd/user/app-com.mitchellh.ghostty.service".source = "${pkgs.ghostty}/share/systemd/user/app-com.mitchellh.ghostty.service";

    "systemd/user/app-com.mitchellh.ghostty.service.d/overrides.conf" = {
      text = ''
        [Unit]
        X-SwitchMethod=keep-old
        X-Reload-Triggers=${config.xdg.config.files."ghostty/config".source}
      '';
    };
  };

  # HM's ghostty systemd integration also did `dbus.packages = [ghostty]`,
  # which links the package's D-Bus service files into
  # $XDG_DATA_HOME/dbus-1/services/ (single file, so no symlinkJoin needed).
  xdg.data.files."dbus-1/services/com.mitchellh.ghostty.service".source = "${pkgs.ghostty}/share/dbus-1/services/com.mitchellh.ghostty.service";
}
