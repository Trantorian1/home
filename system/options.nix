{lib, ...}: {
  perSystem = {...}: {
    options.system = {
      iso = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
      };

      vm = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
      };
    };
  };
}
