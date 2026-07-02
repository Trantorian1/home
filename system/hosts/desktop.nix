{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "desktop";
    hardware.facter.reportPath = ../nix/hardware/desktop.json;

    disks.main = "/dev/disk/by-path/pci-0000:11:00.0-nvme-1";
  };

  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.desktop];
  };
}
