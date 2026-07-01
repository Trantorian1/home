{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.qemu = {...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "qemu";
    hardware.facter.reportPath = ../nix/hardware/qemu.json;
  };

  flake.nixosConfigurations.qemu = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.qemu];
  };
}
