# Based off the firefox-addons NUR expressions by Robert Helgesson
#
# https://gitlab.com/rycee/nur-expressions
{
  pkgs,
  lib,
  ...
}: let
  # https://gitlab.com/rycee/nur-expressions/-/blob/a3569b6df9a8071c156af09c2b3f1ffc32d758b9/lib/mozilla.nix
  buildMozillaXpiAddon = lib.makeOverridable (
    {
      pname,
      version,
      addonId,
      url,
      sha256,
      meta,
      ...
    }:
      pkgs.stdenv.mkDerivation {
        name = "${pname}-${version}";

        inherit meta;

        src = pkgs.fetchurl {inherit url sha256;};

        preferLocalBuild = true;
        allowSubstitutes = true;

        passthru = {
          inherit addonId;
        };

        buildCommand = ''
          dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
          mkdir -p "$dst"
          install -v -m644 "$src" "$dst/${addonId}.xpi"
        '';
      }
  );
in {
  # https://gitlab.com/rycee/nur-expressions/-/blob/a3569b6df9a8071c156af09c2b3f1ffc32d758b9/pkgs/firefox-addons/generated-firefox-addons.nix

  darkreader = buildMozillaXpiAddon {
    pname = "darkreader";
    version = "4.9.128";
    addonId = "addon@darkreader.org";
    url = "https://addons.mozilla.org/firefox/downloads/file/4859299/darkreader-4.9.128.xpi";
    sha256 = "31be69e5e783e30dc255ee357f2a7233486f801cba061560f1a44deb9603296f";
    meta = with lib; {
      homepage = "https://darkreader.org/";
      description = "Dark mode for every website. Take care of your eyes, use dark theme for night and daily browsing.";
      license = licenses.mit;
      mozPermissions = [
        "alarms"
        "contextMenus"
        "storage"
        "tabs"
        "theme"
        "<all_urls>"
      ];
      platforms = platforms.all;
    };
  };

  ublock-origin = buildMozillaXpiAddon {
    pname = "ublock-origin";
    version = "1.72.2";
    addonId = "uBlock0@raymondhill.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/4888680/ublock_origin-1.72.2.xpi";
    sha256 = "40c315b0da7871868155ecfae7a50a58dfa0920aebd865e008214986f1b7c578";
    meta = with lib; {
      homepage = "https://github.com/gorhill/uBlock#ublock-origin";
      description = "Finally, an efficient wide-spectrum content blocker. Easy on CPU and memory.";
      license = licenses.gpl3;
      mozPermissions = [
        "alarms"
        "https://www.google.com.pr/search?*"
        "https://www.google.ps/search?*"
        "https://www.google.pt/search?*"
        "https://www.google.com.py/search?*"
        "https://www.google.com.qa/search?*"
        "https://www.google.ro/search?*"
        "https://www.google.ru/search?*"
        "https://www.google.rw/search?*"
        "https://www.google.com.sa/search?*"
        "https://www.google.com.sb/search?*"
        "https://www.google.sc/search?*"
        "https://www.google.se/search?*"
        "https://www.google.com.sg/search?*"
        "https://www.google.sh/search?*"
        "https://www.google.si/search?*"
        "https://www.google.sk/search?*"
        "https://www.google.com.sl/search?*"
        "https://www.google.sn/search?*"
        "https://www.google.so/search?*"
        "https://www.google.sm/search?*"
        "https://www.google.sr/search?*"
        "https://www.google.st/search?*"
        "https://www.google.com.sv/search?*"
        "https://www.google.td/search?*"
        "https://www.google.tg/search?*"
        "https://www.google.co.th/search?*"
        "https://www.google.com.tj/search?*"
        "https://www.google.tk/search?*"
        "https://www.google.tl/search?*"
        "https://www.google.tm/search?*"
        "https://www.google.tn/search?*"
        "https://www.google.to/search?*"
        "https://www.google.com.tr/search?*"
        "https://www.google.tt/search?*"
        "https://www.google.com.tw/search?*"
        "https://www.google.co.tz/search?*"
        "https://www.google.com.ua/search?*"
        "https://www.google.co.ug/search?*"
        "https://www.google.co.uk/search?*"
        "https://www.google.com.uy/search?*"
        "https://www.google.co.uz/search?*"
        "https://www.google.com.vc/search?*"
        "https://www.google.co.ve/search?*"
        "https://www.google.vg/search?*"
        "https://www.google.co.vi/search?*"
        "https://www.google.com.vn/search?*"
        "https://www.google.vu/search?*"
        "https://www.google.ws/search?*"
        "https://www.google.rs/search?*"
        "https://www.google.co.za/search?*"
        "https://www.google.co.zm/search?*"
        "https://www.google.co.zw/search?*"
        "https://www.google.cat/search?*"
      ];
      platforms = platforms.all;
    };
  };

  sponsorblock = buildMozillaXpiAddon {
    pname = "sponsorblock";
    version = "6.1.6";
    addonId = "sponsorBlocker@ajay.app";
    url = "https://addons.mozilla.org/firefox/downloads/file/4870235/sponsorblock-6.1.6.xpi";
    sha256 = "ab8e4cc26e68070c3c6f379b253330b95677e2d25b52149580daa879cf9ba954";
    meta = with lib; {
      homepage = "https://sponsor.ajay.app";
      description = "Easily skip YouTube video sponsors. When you visit a YouTube video, the extension will check the database for reported sponsors and automatically skip known sponsors. You can also report sponsors in videos. Other browsers: https://sponsor.ajay.app";
      license = licenses.lgpl3;
      mozPermissions = [
        "storage"
        "scripting"
        "unlimitedStorage"
        "https://sponsor.ajay.app/*"
        "https://*.youtube.com/*"
        "https://www.youtube-nocookie.com/embed/*"
      ];
      platforms = platforms.all;
    };
  };

  return-youtube-dislikes = buildMozillaXpiAddon {
    pname = "return-youtube-dislikes";
    version = "3.0.0.18";
    addonId = "{762f9885-5a13-4abd-9c77-433dcd38b8fd}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4371820/return_youtube_dislikes-3.0.0.18.xpi";
    sha256 = "2d33977ce93276537543161f8e05c3612f71556840ae1eb98239284b8f8ba19e";
    meta = with lib; {
      description = "Returns ability to see dislike statistics on youtube";
      license = licenses.gpl3;
      mozPermissions = [
        "activeTab"
        "*://*.youtube.com/*"
        "storage"
        "*://returnyoutubedislikeapi.com/*"
      ];
      platforms = platforms.all;
    };
  };
}
