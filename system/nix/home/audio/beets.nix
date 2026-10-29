{
  config,
  pkgs,
  ...
}: {
  packages = [pkgs.beets];

  xdg.config.files."beets/config.yaml" = {
    generator = (pkgs.formats.yaml {}).generate "beets-config";
    value = {
      directory = "${config.directory}/Music";
      library = "${config.directory}/.cache/beets/database";
      import.copy = false;

      plugins = [
        "fetchart"
        "embedart"
        "lyrics"
        "rewrite"
        "scrub"
        "musicbrainz"
      ];
      match = {
        preferred.media = [
          "cd"
          "digital media over internet"
        ];
        prefer_exact = true;
      };
    };
  };
}
