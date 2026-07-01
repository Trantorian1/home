{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "desktop";
    config.hardware.facter.reportPath = ../nix/hardware/desktop.json;
  };

  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.desktop];
  };
}
