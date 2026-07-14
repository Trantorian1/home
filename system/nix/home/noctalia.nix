{noctalia, ...}: {
  imports = [noctalia.homeModules.default];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # Disables startup greeter.
    # This needs to be set manually as we are using impermanence.
    settings.shell.setup_wizard_enabled = false;
  };
}
