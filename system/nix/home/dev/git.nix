{
  lib,
  pkgs,
  ...
}: {
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
