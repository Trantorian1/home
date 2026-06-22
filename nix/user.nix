{pkgs, ...}: {
  users.users.trantorian = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "test";
    packages = with pkgs; [ghostty];
  };

  users.mutableUsers = false;

  # Auto-login user
  services.displayManager.defaultSession = "gnome";
  services.displayManager.autoLogin.user = "trantorian";
}
