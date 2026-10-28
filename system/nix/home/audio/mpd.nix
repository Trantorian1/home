{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.directory;

  # HM's services.mpd.dataDir defaulted to $XDG_DATA_HOME/mpd (xdg.dataHome
  # defaulted to ~/.local/share for stateVersion >= 20.09).
  dataDir = "${home}/.local/share/mpd";

  extraConfig = ''
    audio_output {
        type            "pipewire"
        name            "PipeWire"
    }

    log_file            "${home}/.cache/mpd/log"
    sticker_file        "${home}/.cache/mpd/sticker.db"
  '';

  # HM's generatedConfig (modules/services/mpd.nix, Linux branch) with this
  # project's values; port == 6600 so the `port` line is omitted by HM too.
  # The final fragment keeps HM's wrapper string: it renders as
  # "${extraConfig}\n", i.e. one trailing newline beyond extraConfig's own,
  # which must be preserved for byte-identity.
  mpdConf =
    ''
      music_directory     "${home}/Music"
      playlist_directory  "${home}/.config/mpd/playlists"
      db_file             "${home}/.cache/mpd/database"
      state_file          "${dataDir}/state"
      sticker_file        "${dataDir}/sticker.sql"

      bind_to_address     "localhost"
    ''
    + lib.optionalString (extraConfig != "")
    ''
      ${extraConfig}
    '';

  # Like HM, the generated config is passed from the store as a CLI argument;
  # no mpd.conf is placed in the home directory.
  mpdConfFile = pkgs.writeText "mpd.conf" mpdConf;
in {
  # Replaces home-manager's services.mpd: installs mpd, runs it as a systemd
  # user service with the generated store config, and provides the MPD_HOST /
  # MPD_PORT session variables (was enableSessionVariables, default on) via
  # fish conf.d — see the environment-variables note in the plan.
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
      ExecStartPre = ''${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/mkdir -p '${dataDir}' '${home}/.config/mpd/playlists'"'';
    };
  };

  xdg.config.files."fish/conf.d/mpd.fish".text = ''
    # Was services.mpd's session variables (HM default on)
    set -gx MPD_HOST "localhost"
    set -gx MPD_PORT "6600"
  '';
}
