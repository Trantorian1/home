{pkgs, ...}: let
  source = pkgs.fetchFromGitHub {
    owner = "trantorian1";
    repo = "rv";
    rev = "fadc2ffafa30850533190a3478971b698ed10177";
    hash = "sha256-0tHA+kkdxyMX2FnlZG+A6+cDFQgbdQa9lstGauh9K00=";
  };
  rv = import source {inherit (pkgs.stdenv.hostPlatform) system;};
in {
  users.users.trantorian = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "test";

    packages = with pkgs; [
      ghostty
      rv.module.config.rv
    ];
  };

  users.mutableUsers = false;

  # Auto-login user
  services.displayManager.defaultSession = "gnome";
  services.displayManager.autoLogin.user = "trantorian";
}
