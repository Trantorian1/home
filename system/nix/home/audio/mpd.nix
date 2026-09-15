{config, ...}: let
  home = config.home.homeDirectory;
in {
  services.mpd = {
    enable = true;

    dbFile = "${home}/.cache/mpd/database";
    musicDirectory = "${home}/Music";
    playlistDirectory = "${home}/.config/mpd/playlists";

    network = {
      listenAddress = "localhost";
      port = 6600;
    };

    extraConfig = ''
      audio_output {
          type            "pipewire"
          name            "PipeWire"
      }

      log_file            "${home}/.cache/mpd/log"
      sticker_file        "${home}/.cache/mpd/sticker.db"
    '';
  };
}
