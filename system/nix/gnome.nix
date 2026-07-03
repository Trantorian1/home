{pkgs, ...}: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Remove auto-included apps
  services.gnome.core-apps.enable = false;
  environment.gnome.excludePackages = [pkgs.gnome-tour];
  services.xserver.excludePackages = [pkgs.xterm];

  # Add back nautilus for file picking
  environment.systemPackages = [pkgs.nautilus];
}
