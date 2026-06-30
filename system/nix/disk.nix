{...}: {
  disko.devices = {
    disk = {
      my-disk = {
        type = "disk";
        device = "/dev/disk/by-path/pci-0000:00:03.0";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              type = "EF02"; # for grub MBR
              size = "1M";
              priority = 1; # Needs to be first partition
            };
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
