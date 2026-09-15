{...}: {
  programs.git = {
    enable = true;

    settings = {
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
