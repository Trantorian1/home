{
  zen-browser,
  modulesPath,
  pkgs,
  lib,
  home,
  ...
}: let
  mkFirefox = import "${modulesPath}/programs/firefox/mkFirefoxModule.nix";

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

  "ublock-origin" = buildMozillaXpiAddon {
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

  "sponsorblock" = buildMozillaXpiAddon {
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
in {
  imports = [
    (mkFirefox {
      inherit (zen-browser.meta) description;

      modulePath = [
        "programs"
        "zen-browser"
      ];

      name = "zen-browser";
      wrappedPackageName = "zen-browser";
      unwrappedPackageName = "zen-browser-unwrapped";

      platforms.linux.configPath = ".config/zen";
      platforms.darwin.configPath = abort "darwin not supported";
    })
  ];

  programs.zen-browser = {
    enable = true;
    package = zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

    languagePacks = ["en-US"];

    policies = {
      # Updates & Background Services
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;

      # Feature Disabling
      DisableBuiltinPDFViewer = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;

      # Access Restrictions
      BlockAboutConfig = false;
      BlockAboutProfiles = true;
      BlockAboutSupport = true;

      # UI and Behavior
      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true;
      OfferToSaveLogins = false;
      DefaultDownloadDirectory = "${home}/Downloads";
    };

    profiles.default = {
      settings = {
        # Enabling google safe browsing
        # https://librewolf.net/docs/settings/#enable-google-safe-browsing
        "browser.safebrowsing.malware.enabled" = true;
        "browser.safebrowsing.phishing.enabled" = true;
        "browser.safebrowsing.blockedURIs.enabled" = true;
        "browser.safebrowsing.provider.google4.gethashURL" = "https://safebrowsing.googleapis.com/v4/fullHashes:find?$ct=application/x-protobuf&key=%GOOGLE_SAFEBROWSING_API_KEY%&$httpMethod=POST";
        "browser.safebrowsing.provider.google4.updateURL" = "https://safebrowsing.googleapis.com/v4/threatListUpdates:fetch?$ct=application/x-protobuf&key=%GOOGLE_SAFEBROWSING_API_KEY%&$httpMethod=POST";
        "browser.safebrowsing.provider.google.gethashURL" = "https://safebrowsing.google.com/safebrowsing/gethash?client=SAFEBROWSING_ID&appver=%MAJOR_VERSION%&pver=2.2";
        "browser.safebrowsing.provider.google.updateURL" = "https://safebrowsing.google.com/safebrowsing/downloads?client=SAFEBROWSING_ID&appver=%MAJOR_VERSION%&pver=2.2&key=%GOOGLE_SAFEBROWSING_API_KEY%";
        "browser.safebrowsing.downloads.enabled" = true;

        # Do not restore tabs on crash
        # https://librewolf.net/docs/settings/#stop-librewolf-from-resuming-after-a-crash
        "browser.sessionstore.resume_from_crash" = false;

        # Disable welcome screen
        "zen.welcome-screen.seen" = true;

        # Allow extensions installed via profiles.default.extensions
        "extensions.autoDisableScopes" = 0;

        # Disable history
        "places.history.enabled" = false;
        "browser.startup.page" = 1;

        # Disable import bookmarks
        "browser.bookmarks.addedImportButton" = false;
        "browser.toolbars.bookmarks.visibility" = "always";

        # Homepage
        "browser.startup.homepage" = lib.strings.join "|" [
          "https://discord.com/login"
          "https://github.com/login"
          "https://habitica.com/login"
        ];
      };

      # Extensions
      extensions.packages = [
        darkreader
        ublock-origin
        sponsorblock
        return-youtube-dislikes
      ];

      # Bookmarks
      bookmarks = {
        force = true;
        settings = [
          {
            name = "toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "odoo";
                url = "https://www.odoo.com/web/login";
              }
              {
                name = "i-suite";
                url = "https://client.azursync.com/cnx/iSuiteExpert/Connexion";
              }
              {
                name = "linkedin";
                url = "https://linkedin.com/login";
              }
            ];
          }
        ];
      };

      # Search
      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";

        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@no"];
          };

          "NixOS Wiki" = {
            urls = [
              {
                template = "https://wiki.nixos.org/w/index.php";
                params = [
                  {
                    name = "search";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@nw"];
          };

          youtube = {
            urls = [
              {
                template = "https://www.youtube.com/results";
                params = [
                  {
                    name = "search_query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://www.youtube.com/favicon.ico";
            definedAliases = ["@yt"];
          };
        };
      };
    };
  };
}
