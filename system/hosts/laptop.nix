{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.laptop = {config, ...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "laptop";
    hardware.facter.reportPath = ../nix/hardware/laptop.json;

    installer.disks.main = "/dev/disk/by-path/pci-0000:01:00.0-nvme-1";
  };

  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs;};
    modules = [self.nixosModules.laptop];
  };
}
