{config, ...}: let
  home = config.home.homeDirectory;
in {
  programs.beets = {
    enable = true;

    settings = {
      directory = "${home}/Music";
      library = "${home}/.cache/beets/database";
      import.copy = false;

      plugins = ["fetchart" "embedart" "lyrics" "rewrite" "scrub"];
      match = {
        preferred.media = ["cd" "digital media over internet"];
        prefer_exact = true;
      };
    };
  };
}
