{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.qemu = {config, ...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "qemu";
    hardware.facter.reportPath = ../nix/hardware/qemu.json;
    services.spice-vdagentd.enable = true;

    installer.disks.main = "/dev/disk/by-path/pci-0000:00:04.0";
  };

  flake.nixosConfigurations.qemu = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.qemu];
  };
}
