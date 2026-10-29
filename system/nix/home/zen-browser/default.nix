{
  inputs,
  lib,
  pkgs,
  ...
}: let
  zenPackage = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

  extensions = pkgs.callPackage ./extensions.nix {};

  # ---------------------------------------------------------------------
  # profiles.ini — single "default" profile.
  #
  # Rendered with the same generator and (sorted) data as the old
  # home-manager module, so the file stays byte-identical.
  # ---------------------------------------------------------------------
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

  # ---------------------------------------------------------------------
  # Bookmarks — renderer ported from home-manager's programs/firefox
  # bookmarks module (rev 6750249). Renders Netscape-HTML into the nix
  # store; user.js points at it via browser.bookmarks.file, which Firefox
  # imports on first use in a fresh profile.
  # ---------------------------------------------------------------------
  bookmarks = [
    {
      name = "toolbar";
      toolbar = true;
      bookmarks = [
        {
          name = "odoo";
          url = "https://www.odoo.com/web/login";
          tags = [];
          keyword = null;
        }
        {
          name = "i-suite";
          url = "https://client.azursync.com/cnx/iSuiteExpert/Connexion";
          tags = [];
          keyword = null;
        }
        {
          name = "linkedin";
          url = "https://linkedin.com/login";
          tags = [];
          keyword = null;
        }
      ];
    }
  ];

  bookmarksHtml = let
    indent = level: lib.concatStringsSep "" (map (lib.const "  ") (lib.range 1 level));

    bookmarkToHTML = indentLevel: bookmark: ''${indent indentLevel}<DT><A HREF="${lib.escapeXML bookmark.url}" ADD_DATE="1" LAST_MODIFIED="1"${
        lib.optionalString (bookmark.keyword != null) " SHORTCUTURL=\"${lib.escapeXML bookmark.keyword}\""
      }${
        lib.optionalString (bookmark.tags != []) " TAGS=\"${lib.escapeXML (lib.concatStringsSep "," bookmark.tags)}\""
      }>${lib.escapeXML bookmark.name}</A>'';

    directoryToHTML = indentLevel: directory: ''
      ${indent indentLevel}<DT>${
        if directory.toolbar
        then ''<H3 ADD_DATE="1" LAST_MODIFIED="1" PERSONAL_TOOLBAR_FOLDER="true">Bookmarks Toolbar''
        else ''<H3 ADD_DATE="1" LAST_MODIFIED="1">${lib.escapeXML directory.name}''
      }</H3>
      ${indent indentLevel}<DL><p>
      ${allItemsToHTML (indentLevel + 1) directory.bookmarks}
      ${indent indentLevel}</DL><p>'';

    separatorToHTML = indentLevel: "${indent indentLevel}<HR>";

    itemToHTMLOrRecurse = indentLevel: item:
      if item ? "url"
      then bookmarkToHTML indentLevel item
      else if item == "separator"
      then separatorToHTML indentLevel
      else directoryToHTML indentLevel item;

    allItemsToHTML = indentLevel: items: lib.concatStringsSep "\n" (map (itemToHTMLOrRecurse indentLevel) items);
  in
    pkgs.writeText "bookmarks.html" ''
      <!DOCTYPE NETSCAPE-Bookmark-file-1>
      <!-- This is an automatically generated file.
        It will be read and overwritten.
        DO NOT EDIT! -->
      <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
      <TITLE>Bookmarks</TITLE>
      <H1>Bookmarks Menu</H1>
      <DL><p>
      ${allItemsToHTML 1 bookmarks}
      </DL>
    '';

  # ---------------------------------------------------------------------
  # user.js — declarative prefs: the same 19 settings as the old module,
  # plus the two bookmark-import prefs its renderer added. Rendered in
  # sorted order to match the legacy output (home-manager's option
  # machinery sorted the attrset; Firefox applies prefs idempotently).
  # ---------------------------------------------------------------------
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

    # Allow declaratively installed extensions
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

    # Homepage (multiple pages would be joined with "|")
    "browser.startup.homepage" = lib.strings.join "|" [
      "https://habitica.com/login"
    ];
  };

  userJs =
    ''
      // Managed by Nix (hjem). DO NOT EDIT.

    ''
    + lib.concatStrings (
      lib.mapAttrsToList (name: value: "user_pref(\"${name}\", ${builtins.toJSON value});\n") (
        # builtins.listToAttrs sorts by name, matching the legacy output.
        lib.listToAttrs (
          lib.attrsToList ({
              "browser.bookmarks.file" = toString bookmarksHtml;
              "browser.places.importBookmarksHTML" = true;
            }
            // settings)
        )
      )
    );

  # ---------------------------------------------------------------------
  # search.json.mozlz4 — ported from home-manager's programs/firefox
  # search module (rev 6750249). Builds the profile's search.json,
  # embeds Mozilla's default-engine integrity hashes (salted with the app
  # name read from the package's application.ini) and compresses it with
  # mozlz4a. The runCommand script is kept verbatim; only the _loadPath
  # prefix was rebranded ([home-manager] -> [hjem]). Engines are emitted
  # sorted by id to match the legacy output order.
  # ---------------------------------------------------------------------
  profilePath = "default";
  defaultEngine = "ddg-noai";
  privateDefaultEngine = "ddg-noai";

  internalFieldNames =
    (lib.genAttrs [
      "name"
      "isAppProvided"
      "loadPath"
      "updateInterval"
      "updateURL"
      "iconMapObj"
      "metaData"
      "orderHint"
      "definedAliases"
      "urls"
    ] (name: "_${name}"))
    // {searchForm = "__searchForm";};

  iconUrl = icon:
    if lib.isPath icon || lib.hasPrefix "/" icon
    then "file://${icon}"
    else icon;

  processCustomEngineInput = input:
    {name = input.id;}
    // (lib.removeAttrs input ["icon"])
    // lib.optionalAttrs (input ? icon || input ? iconMapObj) {
      iconMapObj = lib.mapAttrs (_name: iconUrl) (
        (lib.optionalAttrs (input ? icon) {"16" = input.icon;})
        // (input.iconMapObj or {})
      );
    }
    // {loadPath = "[hjem]/zen-browser/${input.id}";};

  processEngineInput = id: input: let
    requiredInput = {
      inherit id;
      isAppProvided = input.isAppProvided or (lib.removeAttrs input ["metaData"] == {});
      metaData = input.metaData or {};
    };
  in
    if requiredInput.isAppProvided
    then requiredInput
    else processCustomEngineInput (input // requiredInput);

  buildEngineConfig = name: input:
    lib.mapAttrs' (n: value: {
      name = internalFieldNames.${n} or n;
      inherit value;
    }) (processEngineInput name input);

  searchEngines = {
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

  searchSettings = {
    version = 12;
    # listToAttrs sorts by engine id, matching the legacy output order.
    engines = lib.attrValues (
      lib.listToAttrs (lib.attrsToList (lib.mapAttrs buildEngineConfig searchEngines))
    );
    metaData = {
      defaultEngineId = defaultEngine;
      defaultEngineIdHash = "@hash@";
      privateDefaultEngineId = privateDefaultEngine;
      privateDefaultEngineIdHash = "@privateHash@";
      useSavedOrder = false;
    };
  };

  disclaimer =
    "By modifying this file, I agree that I am doing so "
    + "only within @appName@ itself, using official, user-driven search "
    + "engine selection processes, and in a way which does not circumvent "
    + "user consent. I acknowledge that any attempt to change this file "
    + "from outside of @appName@ is a malicious act, and will be responded "
    + "to accordingly.";

  salt = "${profilePath}${defaultEngine}" + disclaimer;
  privateSalt = "${profilePath}${privateDefaultEngine}" + disclaimer;

  appNameVariable = ''
    applicationIni="$(find ${lib.escapeShellArg zenPackage} -maxdepth 3 -path ${lib.escapeShellArg zenPackage}'/lib/*/application.ini' -print -quit)"
    if test -n "$applicationIni"; then
      appName="$(sed -n 's/^Name=\(.*\)$/\1/p' "$applicationIni" | head -n1)"
    else
      appName=${lib.escapeShellArg "zen-browser"}
    fi
  '';

  searchFile =
    pkgs.runCommand "search.json.mozlz4"
    {
      nativeBuildInputs = with pkgs; [
        mozlz4a
        openssl
      ];
      json = builtins.toJSON searchSettings;
      inherit salt privateSalt;
    }
    ''
      ${appNameVariable}

      salt=''${salt//@appName@/"$appName"}
      privateSalt=''${privateSalt//@appName@/"$appName"}

      if [[ -n $salt ]]; then
        export hash=$(echo -n "$salt" | openssl dgst -sha256 -binary | base64)
        export privateHash=$(echo -n "$privateSalt" | openssl dgst -sha256 -binary | base64)
        mozlz4a <(substituteStream json search.json.in --subst-var hash --subst-var privateHash) "$out"
      else
        mozlz4a <(echo "$json") "$out"
      fi
    '';

  # Shared add-on directory. Same five add-ons as the old module; the
  # buildEnv is renamed from "hm-firefox-extensions" (contents identical).
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
  # The plain wrapped zen package — identical to the old setup, where HM's
  # mkFirefoxModule also returned the plain package: the zen flake's
  # callPackage-derived override does not expose the wrapper's cfg, so its
  # `policies` block was never baked in. (If policies are ever wanted,
  # call the wrapper directly with cfg = { zen.policies = ... }.)
  packages = [zenPackage];

  # No per-entry clobber flags: the user-level `clobberFiles = true`
  # (system/nix/home/default.nix) is the default for every file entry,
  # which is what the old module evaluated to as well.
  xdg.config.files = {
    "zen/profiles.ini" = {text = profilesIni;};

    "zen/default/.keep" = {text = "";};

    "zen/default/user.js" = {text = userJs;};

    "zen/default/search.json.mozlz4" = {source = searchFile;};

    "zen/default/extensions" = {
      source = "${extensionsEnv}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
    };
  };
}
