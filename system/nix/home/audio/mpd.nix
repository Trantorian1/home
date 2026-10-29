{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.directory;

  confDir = "${home}/.cache/mpd";
  dataDir = "${home}/.local/share/mpd";

  extraConfig = ''
    audio_output {
        type            "pipewire"
        name            "PipeWire"
    }

    log_file            "${confDir}/log"
    sticker_file        "${confDir}/sticker.db"
  '';

  mpdConf =
    ''
      music_directory     "${home}/Music"
      playlist_directory  "${confDir}/playlists"
      db_file             "${confDir}/database"
      state_file          "${dataDir}/state"
      sticker_file        "${dataDir}/sticker.sql"

      bind_to_address     "localhost"
    ''
    + lib.optionalString (extraConfig != "")
    ''
      ${extraConfig}
    '';

  mpdConfFile = pkgs.writeText "mpd.conf" mpdConf;
in {
  packages = [pkgs.mpd];

  systemd.services.mpd = {
    description = "Music Player Daemon";
    after = [
      "network.target"
      "sound.target"
    ];
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "notify";
      ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon ${mpdConfFile}";
      ExecStartPre = ''${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/mkdir -p '${confDir}' '${dataDir}' '${home}/.config/mpd/playlists'"'';
    };
  };

  xdg.config.files."fish/conf.d/mpd.fish".text = ''
    # Was services.mpd's session variables (HM default on)
    set -gx MPD_HOST "localhost"
    set -gx MPD_PORT "6600"
  '';
}
