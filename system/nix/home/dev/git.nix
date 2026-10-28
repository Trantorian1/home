{
  lib,
  pkgs,
  ...
}: {
  # Replaces home-manager's `programs.git`: installs git and renders the XDG
  # git config with the same INI generator HM used (`lib.generators.toGitINI`),
  # so the resulting file is byte-identical to the old setup.
  packages = [pkgs.git];

  xdg.config.files."git/config" = {
    generator = lib.generators.toGitINI;
    value = {
      user = {
        name = "trantorian";
        email = "114066155+Trantorian1@users.noreply.github.com";
      };
      core = {
        pager = "";
        editor = "nvim";
      };
    };
  };
}
