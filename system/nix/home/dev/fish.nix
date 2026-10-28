{
  lib,
  osConfig,
  ...
}: let
  rv = lib.getExe osConfig.rv.editor;
in {
  # Replaces home-manager's `programs.fish`. Fish itself is provided by the
  # system-level programs.fish (see system/nix/user.nix), so no package is
  # added here. HM wrote its generated config to fish/config.fish, which is
  # also where this lives; the lsd aliases live in fish/conf.d/lsd.fish.
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
