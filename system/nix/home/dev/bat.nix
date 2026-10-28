{
  lib,
  pkgs,
  ...
}: {
  # Replaces home-manager's programs.bat plus the parts HM's default-on
  # programs.ghostty.installBatSyntax fed into it: installs bat, writes the
  # bat config (rendered as --key=value lines exactly like HM's toConfigFile),
  # links the ghostty syntax file, and sets MANPAGER for fish sessions (was
  # home.sessionVariables; Hjem's sessionVariables cannot reach a fish
  # session — see the environment-variables note in the plan).
  packages = [pkgs.bat];

  xdg.config.files = {
    "bat/config".text =
      lib.generators.toKeyValue {
        mkKeyValue = k: v: "--${k}=${lib.escapeShellArg v}";
        listsAsDuplicateKeys = true;
      } {
        # HM's programs.ghostty.installBatSyntax (default on) set this on
        # programs.bat.config.
        map-syntax = ["$XDG_CONFIG_HOME/ghostty/config:Ghostty Config"];
      };

    "bat/syntaxes/ghostty.sublime-syntax".source = "${pkgs.ghostty}/share/bat/syntaxes/ghostty.sublime-syntax";

    "fish/conf.d/bat.fish".text = ''
      # Was home.sessionVariables.MANPAGER
      set -gx MANPAGER "bat -l man -p"
    '';
  };
}
