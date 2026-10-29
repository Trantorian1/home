{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

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
