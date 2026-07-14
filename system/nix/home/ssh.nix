{
  osConfig,
  config,
  ...
}: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      github = {
        hostname = "ssh.github.com";
        identityFile = "~/.ssh/github";
      };
    };
  };

  sops.age = {
    keyFile = "/persistent/${config.home.homeDirectory}/.config/sops/age/keys.txt";
    generateKey = false;
  };

  sops.secrets."host/${osConfig.networking.hostName}/master" = {
    sopsFile = ../../../secrets/ssh.dev.yaml;
    path = "${config.home.homeDirectory}/.ssh/id_ed25519";
  };

  sops.secrets."host/${osConfig.networking.hostName}/github" = {
    sopsFile = ../../../secrets/ssh.dev.yaml;
    path = "${config.home.homeDirectory}/.ssh/github";
  };
}
