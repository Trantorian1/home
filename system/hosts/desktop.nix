{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {...}: {
    imports = [self.nixosModules.core];

    networking.hostName = "desktop";
    hardware.facter.reportPath = ../nix/hardware/desktop.json;

    installer.disks.main = "/dev/disk/by-path/pci-0000:11:00.0-nvme-1";

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub.efiInstallAsRemovable = false;
  };

  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.desktop];
  };
}
