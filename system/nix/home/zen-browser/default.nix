{
  inputs,
  lib,
  pkgs,
  ...
}: let
  zenPackage = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  profilesIni = lib.generators.toINI {} {
    General = {
      StartWithLastProfile = 1;
      Version = 2;
    };

    Profile0 = {
      Default = 1;
      IsRelative = 1;
      Name = "default";
      Path = "default";
    };
  };

  extensions = pkgs.callPackage ./extensions.nix {};
  extensionsEnv = pkgs.buildEnv {
    name = "zen-browser-extensions";
    paths = [
      extensions.darkreader
      extensions.ublock-origin
      extensions.sponsorblock
      extensions.return-youtube-dislikes
      extensions.proton-pass
    ];
  };
in {
  packages = [zenPackage];

  xdg.config.files = {
    "zen/profiles.ini" = {text = profilesIni;};

    "zen/default/.keep" = {text = "";};

    "zen/default/user.js" = {text = pkgs.callPackage ./userJs.nix {};};

    "zen/default/search.json.mozlz4" = {source = pkgs.callPackage ./search.nix {inherit zenPackage;};};

    "zen/default/extensions" = {
      source = "${extensionsEnv}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
    };
  };
}
