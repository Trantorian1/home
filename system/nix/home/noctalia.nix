{noctalia, ...}: {
  imports = [noctalia.homeModules.default];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      # Automatic theming for applications built with GTK, Qt, and KDE Plasma
      # toolkits
      theme.templates.builtin_ids = ["gtk4"];

      # Disables startup greeter.
      # This needs to be set manually as we are using impermanence.
      shell.setup_wizard_enabled = false;
    };
  };
}
