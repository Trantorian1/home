{lib, ...}: {
  options.disks.main = lib.mkOption {
    type = lib.types.str;
    description = "Main disk on which to install the system";
  };
}
