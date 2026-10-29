{
  lib,
  osConfig,
  ...
}: let
  rv = lib.getExe osConfig.rv.editor;
in {
  xdg.config.files."fish/config.fish".text = ''
    # Fish user configuration (replaces home-manager's programs.fish)

    status is-interactive; and begin
      # Aliases (was programs.fish.shellAliases)
      alias e exit
      alias rv ${lib.escapeShellArg "nix develop --command ${rv} || ${rv}"}

      # Disable the default greeting
      set fish_greeting
    end
  '';
}
