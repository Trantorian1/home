{...}: {
  files.".ssh/config".text = ''
    Host github.com
      identitiesOnly yes
      identityFile ~/.ssh/github
      user git

    Host *
      AddKeysToAgent no
      Compression no
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no
      ForwardAgent no
      HashKnownHosts no
      ServerAliveCountMax 3
      ServerAliveInterval 0
      UserKnownHostsFile ~/.ssh/known_hosts
  '';

  files.".ssh" = {
    type = "directory";
    permissions = "0700";
  };
}
