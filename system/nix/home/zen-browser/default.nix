{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # Vendored verbatim from home-manager (rev 6750249, byte-identical to
  # master at the time of vendoring): mkFirefoxModule.nix plus
  # profiles/{bookmark-types,bookmarks,handlers,search}.nix. The file is a
  # module factory; we evaluate it below in a minimal `home.*` option
  # harness and harvest its concrete outputs instead of keeping
  # home-manager as a flake input.
  mkFirefox = import ./mkFirefoxModule.nix;

  extensions = pkgs.callPackage ./extensions.nix {};

  zenPackage = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # The one HM-specific helper the vendored module uses, copied from
  # home-manager's modules/lib/assertions.nix.
  harvesterLib = lib.extend (_final: _prev: {
    hm.assertions.assertPlatform = module: pkgs': platforms: {
      assertion = lib.elem pkgs'.stdenv.hostPlatform.system platforms;
      message = let
        platformsStr = lib.concatStringsSep "\n" (map (p: "  - ${p}") (lib.sort (a: b: a < b) platforms));
      in ''
        The module ${module} does not support your platform. It only supports

        ${platformsStr}'';
    };
  });

  # Minimal `home.*` option stubs so the vendored module evaluates outside
  # home-manager. Only what it actually reads: stateVersion (isWrapped),
  # homeDirectory (wrapper appDataDir path), packages, and file entries.
  homeStubs = {
    options.home.stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "26.05"; # the old project's home-manager state version
    };

    options.home.homeDirectory = lib.mkOption {
      type = lib.types.path;
      default = config.directory; # this Hjem user's home directory
    };

    options.home.packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };

    # Freeform on purpose: we harvest the raw entry values (text / source /
    # force) and map them onto Hjem file entries below.
    options.home.file = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {};
    };

    # The vendored module sets targets.darwin.defaults unconditionally
    # (guarded by mkIf for Darwin). Home-manager provides the option via its
    # darwin target modules, which it imports even on Linux; stub it here.
    # The value never materialises on this platform.
    options.targets.darwin.defaults = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };
  };

  harvested = harvesterLib.evalModules {
    specialArgs = {
      inherit pkgs;
      lib = harvesterLib;
    };
    modules = [
      # Defines the top-level `assertions` option the vendored module sets
      # (home-manager's own module set includes it too).
      (pkgs.path + "/nixos/modules/misc/assertions.nix")

      homeStubs

      (mkFirefox {
        inherit (zenPackage.meta) description;

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

      # The project's programs.zen-browser settings, unchanged from the old
      # module (except config.home.homeDirectory -> config.directory and the
      # bare `zen-browser` extraSpecialArg -> inputs.zen-browser).
      {
        programs.zen-browser = {
          enable = true;
          package = zenPackage;

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
            DefaultDownloadDirectory = "${config.directory}/Downloads";
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
              default = "ddg-noai";
              privateDefault = "ddg-noai";

              engines = {
                "ddg-noai" = {
                  urls = [
                    {
                      template = "https://noai.duckduckgo.com/";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  icon = "https://duckduckgo.com/favicon.ico";
                  definedAliases = ["@ddg"];
                };

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
    ];
  };

  cfg = harvested.config;

  # Map one harvested home.file entry onto a Hjem file entry:
  #   text -> text, source -> source, force -> clobber.
  # `recursive` (the extensions dir) needs no counterpart: a plain Hjem
  # symlink entry with a directory source links the directory itself, which
  # is exactly what HM's recursive symlinking does.
  toHjemFile = entry:
    lib.optionalAttrs (entry.force or false) {clobber = true;}
    // lib.optionalAttrs (entry ? text) {inherit (entry) text;}
    // lib.optionalAttrs (entry ? source) {inherit (entry) source;};

  files = lib.mapAttrs (_: toHjemFile) cfg.home.file;
in {
  # The wrapped zen-browser package. NOTE: identical to the old setup, which
  # did NOT actually bake `policies` into the wrapper — the flake's
  # callPackage-derived `.override` does not expose the wrapper's `cfg`
  # argument, so mkFirefoxModule's wrapPackage takes its "cannot be
  # reconfigured" warning branch and returns the plain wrapped package.
  packages = cfg.home.packages;

  inherit files;
}
