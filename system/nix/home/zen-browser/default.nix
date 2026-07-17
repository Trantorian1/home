{
  zen-browser,
  modulesPath,
  config,
  pkgs,
  lib,
  ...
}: let
  mkFirefox = import "${modulesPath}/programs/firefox/mkFirefoxModule.nix";
  extensions = pkgs.callPackage ./extensions.nix {};
in {
  # See https://github.com/nix-community/home-manager/blob/a45a7c451455a51ae740ec3bce4024b312809c29/modules/programs/librewolf.nix#L31
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
      PasswordManagerEnabled = false;

      # Access Restrictions
      BlockAboutConfig = false;
      BlockAboutProfiles = true;
      BlockAboutSupport = true;

      # UI and Behavior
      DisplayMenuBar = "never";
      DontCheckDefaultBrowser = true;
      HardwareAcceleration = true;
      OfferToSaveLogins = false;
      DefaultDownloadDirectory = "${config.home.homeDirectory}/Downloads";
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

        # Disable password popups
        "signon.generation.enabled" = false;
        "signon.autofillForms" = false;
        "signon.rememberSignons" = false;

        # Homepage
        "browser.startup.homepage" = lib.strings.join "|" [
          "https://discord.com/login"
          "https://github.com/login"
          "https://habitica.com/login"
        ];
      };

      # Extensions
      extensions.packages = [
        extensions.darkreader
        extensions.ublock-origin
        extensions.sponsorblock
        extensions.return-youtube-dislikes
        extensions.proton-pass
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
