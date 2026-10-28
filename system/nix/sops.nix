{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Owns all sops.* configuration for the dev user's SSH keys. Kept out of
  # configuration.nix (per request) and out of the home namespace; imported by
  # ./default.nix instead. Self-contained: it imports the sops-nix NixOS module.
  sops.defaultSopsFile = ../../secrets/ssh.dev.yaml;
  sops.age.keyFile = "/persistent/home/dev/.config/sops/age/keys.txt"; # placed by bootstrap; unchanged
  sops.age.generateKey = false;

  sops.secrets."host/${config.networking.hostName}/master" = {
    owner = "dev";
    path = "/home/dev/.ssh/id_ed25519";
  };
  sops.secrets."host/${config.networking.hostName}/github" = {
    owner = "dev";
    path = "/home/dev/.ssh/github";
  };
}
