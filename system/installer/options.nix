{lib, ...}: {
  options.installer.targetSystem = lib.mkOption {
    description = "Target system to build";
  };
}
