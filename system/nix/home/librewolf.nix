{lib, ...}: {
  programs.librewolf = {
    enable = true;

    # Bookmarks
    profiles.default.bookmarks = {
      force = true;
      settings = [
        {
          name = "odoo";
          tags = ["accounting"];
          keyword = "odoo";
          url = "https://www.odoo.com/web/login";
        }
        {
          name = "i-suite";
          tags = ["accounting"];
          keyword = "i-suite";
          url = "https://client.azursync.com/cnx/iSuiteExpert/Connexion";
        }
        {
          name = "linkedin";
          tags = ["work"];
          keyword = "linkedin";
          url = "https://linkedin.com/login";
        }
      ];
    };

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

      # Stricter autoplay prevention
      # https://librewolf.net/docs/settings/#use-a-stricter-autoplay-policy
      "media.autoplay.blocking_policy" = 2;

      # Disable history
      "places.history.enabled" = false;

      # Homepage
      "browser.startup.homepage" = lib.strings.join "|" [
        "https://discord.com/login"
        "https://account.proton.me/mail"
        "https://account.proton.me/calendar"
        "https://github.com/login"
        "https://habitica.com/login"
        "https://www.odoo.com/web/login"
      ];

      # Use vertical tabs
      "sidebar.verticalTabs" = true;

      # Default extensions
      "browser.policies.runOncePerModification.extensionsInstall" = ''
        [
          "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi"
        ]
      '';
    };
  };
}
