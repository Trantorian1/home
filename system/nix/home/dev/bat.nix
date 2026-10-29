{
  lib,
  pkgs,
  ...
}: {
  packages = [pkgs.bat];

  xdg.config.files = {
    "bat/config".text =
      lib.generators.toKeyValue {
        mkKeyValue = k: v: "--${k}=${lib.escapeShellArg v}";
        listsAsDuplicateKeys = true;
      } {
        map-syntax = ["$XDG_CONFIG_HOME/ghostty/config:Ghostty Config"];
      };

    "bat/syntaxes/ghostty.sublime-syntax".source = "${pkgs.ghostty}/share/bat/syntaxes/ghostty.sublime-syntax";

    "fish/conf.d/bat.fish".text = ''
      # Was home.sessionVariables.MANPAGER
      set -gx MANPAGER "bat -l man -p"
    '';
  };
}
