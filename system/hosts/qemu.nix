{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.qemu = {...}: {
    networking.hostName = "qemu";
    hardware.facter.reportPath = ../nix/hardware/qemu.json;
  };

  flake.nixosConfigurations.qemu = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.core
      self.nixosModules.qemu
    ];
  };
}
