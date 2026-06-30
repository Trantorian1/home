{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {...}: {
    networking.hostName = "desktop";
    config.hardware.facter.reportPath = ../nix/hardware/desktop.json;
  };

  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.core
      self.nixosModules.desktop
    ];
  };
}
