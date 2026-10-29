# Based off home-manager Firefox search module.
#
# https://github.com/nix-community/home-manager/blob/095fef2f265c3c0da4fe315efba8f8a04495ab34/modules/programs/firefox/profiles/search.nix#L144
{
  zenPackage,
  pkgs,
  lib,
  ...
}: let
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
in
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
  ''
