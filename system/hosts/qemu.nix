{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.qemu = {config, ...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "qemu";
    hardware.facter.reportPath = ../nix/hardware/qemu.json;

    disks.main = "/dev/disk/by-path/pci-0000:00:03.0";
  };

  flake.nixosConfigurations.qemu = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.qemu];
  };
}
