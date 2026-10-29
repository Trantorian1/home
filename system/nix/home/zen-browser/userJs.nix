# Based off home-manager's Firefox bookmark module.
#
# https://github.com/nix-community/home-manager/blob/095fef2f265c3c0da4fe315efba8f8a04495ab34/modules/programs/firefox/profiles/bookmarks.nix
{
  pkgs,
  lib,
  ...
}: let
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
in
  ''
    // Managed by Nix (hjem). DO NOT EDIT.

  ''
  + lib.concatStrings (
    lib.mapAttrsToList (name: value: "user_pref(\"${name}\", ${builtins.toJSON value});\n") (
      lib.listToAttrs (
        lib.attrsToList ({
            "browser.bookmarks.file" = toString bookmarksHtml;
            "browser.places.importBookmarksHTML" = true;
          }
          // settings)
      )
    )
  )
