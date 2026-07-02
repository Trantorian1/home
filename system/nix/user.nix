{
  config,
  pkgs,
  ...
}: {
  users.users.trantorian = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "test";

    packages = with pkgs; [
      ghostty
      config.rv.nvim
      config.rv.editor
    ];
  };

  users.mutableUsers = false;

  # Auto-login user
  services.displayManager.defaultSession = "gnome";
  services.displayManager.autoLogin.user = "trantorian";

  # Make config available in home directory
  environment.etc.nixos.source = "${config.users.users.trantorian.home}/.dotfiles";
}
