{
  config,
  pkgs,
  ...
}: let
  source = pkgs.fetchFromGitHub {
    owner = "trantorian1";
    repo = "rv";
    rev = "fadc2ffafa30850533190a3478971b698ed10177";
    hash = "sha256-0tHA+kkdxyMX2FnlZG+A6+cDFQgbdQa9lstGauh9K00=";
  };
  rv = import source {inherit (pkgs.stdenv.hostPlatform) system;};

  dotfiles = "${config.users.users.trantorian.home}/.dotfiles";
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

  # Make config available in home directory
  nix.nixPath = ["nixos-config=${dotfiles}/configuration.nix"];

  system.activationScripts.seedNixosConfig.text = ''
    if [ ! -e ${dotfiles}/configuration.nix ]; then
      mkdir -p ${dotfiles}
      cp -r --no-preserve=mode ${../.}/* ${dotfiles}
      chown -R trantorian:users ${dotfiles}
    fi
  '';

  systemd.services.generate-factor-report = {
    wantedBy = ["multi-user.target"];
    unitConfig.ConditionPathExists = "!${dotfiles}/facter.json";
    serviceConfig.Type = "oneshot";
    path = [pkgs.nixos-facter];
    script = "nixos-facter -o ${dotfiles}/facter.json";
  };
}
