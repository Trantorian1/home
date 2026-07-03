{
  config,
  pkgs,
  ...
}: {
  users.users.trantorian = {
    isNormalUser = true;
    extraGroups = ["wheel"];

    hashedPassword = "$y$j9T$0E2R1pahxLXhm/m.QVc3x/$bFX5ytzlz2Uh.3YrOA6udtw3rRQO1iYj6pB4cgsLfq1";

    packages = with pkgs; [
      ghostty

      config.rv.nvim
      config.rv.editor

      discord
      librewolf
      typora

      proton-pass
    ];
  };

  users.mutableUsers = false;

  # Auto-login user
  services.displayManager.defaultSession = "gnome";
  services.displayManager.autoLogin.user = "trantorian";

  # Make config available in home directory
  environment.etc.nixos.source = "${config.users.users.trantorian.home}/.dotfiles";

  programs.steam.enable = true;
}
