{
  osConfig,
  config,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/github";
        identitiesOnly = true;
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
