{
  config,
  lib,
  pkgs,
  ...
}: {
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

  xdg.data.files."dbus-1/services/com.mitchellh.ghostty.service".source = "${pkgs.ghostty}/share/dbus-1/services/com.mitchellh.ghostty.service";
}
