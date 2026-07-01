{...}: {
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persistent".neededForBoot = true;

  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=25%"
        "mode=755"
      ];
    };
  };

  disko.devices.disk = {
    main = {
      type = "disk";
      device = "/dev/disk/by-path/pci-0000:00:03.0";

      content.type = "gpt";

      content.partitions.boot = {
        type = "EF02"; # for grub MBR
        size = "1M";
        priority = 1; # Needs to be first partition
      };

      content.partitions.ESP = {
        type = "EF00";
        size = "500M";

        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = ["umask=0077"];
        };
      };

      content.partitions.swap = {
        size = "8G";

        content = {
          type = "swap";
          resumeDevice = true;
        };
      };

      content.partitions.luks = {
        size = "100%";

        content = {
          type = "luks";
          name = "crypted";
          settings.allowDiscards = true;

          content = {
            type = "btrfs";
            extraArgs = ["-f"];

            subvolumes = {
              "/persistent" = {
                mountOptions = ["compress=zstd" "noatime"];
                mountpoint = "/persistent";
              };

              "/nix" = {
                mountOptions = ["compress=zstd" "noatime"];
                mountpoint = "/nix";
              };

              "/tmp" = {
                mountOptions = ["compress=zstd" "noatime"];
                mountpoint = "/tmp";
              };
            };
          };
        };
      };
    };
  };
}
