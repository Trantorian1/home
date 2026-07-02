{config, ...}: let
  home = config.users.users.trantorian.home;
in {
  sops.age = {
    keyFile = "/persistent/${home}/.config/sops/age/keys.txt";
    generateKey = false;
  };

  sops.secrets."host/qemu" = {
    sopsFile = ../../secrets/ssh.dev.yaml;
    owner = config.users.users.trantorian.name;
    path = "${home}/.ssh/id_rsa";
  };
}
