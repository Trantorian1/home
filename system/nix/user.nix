{
  config,
  pkgs,
  ...
}: {
  imports = [./home];

  # Needed since the user's default shell is set to `fish`.
  programs.fish.enable = true;

  programs.wireshark.enable = true;

  # Required by noctalia
  programs.niri.enable = true;
  programs.dconf.enable = true;

  environment.systemPackages = [pkgs.xwayland-satellite];

  users.users.dev = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "wireshark"
    ];

    hashedPassword = "$y$j9T$0E2R1pahxLXhm/m.QVc3x/$bFX5ytzlz2Uh.3YrOA6udtw3rRQO1iYj6pB4cgsLfq1";

    # Do not set user packages here! Use home-manager instead.
    # See `home/default.nix` for more information.
    #
    # packages = with pkgs; [];

    shell = pkgs.fish;
  };

  users.mutableUsers = false;

  # Auto-login user
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.niri}/bin/niri-session";
      user = "dev";
    };
  };
  # Make config available in home directory
  environment.etc.nixos.source = "${config.users.users.dev.home}/.dotfiles";

  programs.steam.enable = true;
}
