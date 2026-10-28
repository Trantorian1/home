{...}: {
  # Replaces home-manager's `programs.ssh`. The config text below is
  # byte-identical to what pinned HM (rev 6750249) rendered for the old
  # settings attrset (verified by evaluating the old module: block order is
  # github.com first, then the "*" block last; directives are sorted
  # alphabetically within each block).
  #
  # Note: HM's `programs.ssh.settings` passes raw names through verbatim
  # (only `header` is a typed option), so the old github.com block's
  # camelCase names were rendered literally. OpenSSH directive names are
  # case-insensitive, so this is functionally identical to
  # User/IdentityFile/IdentitiesOnly; kept as-is for byte fidelity.
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

  # HM created the .ssh parent directory with a plain `mkdir -p`; declare it
  # explicitly as 0700 (the standard for a directory holding private keys,
  # which sops-nix also places here). The Hjem CLI linker preserves existing
  # directory contents and enforces the permissions on every activation
  # (verified with the pinned Hjem CLI against a pre-populated .ssh dir).
  files.".ssh" = {
    type = "directory";
    permissions = "0700";
  };
}
