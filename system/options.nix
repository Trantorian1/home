{lib, ...}: {
  perSystem = {...}: {
    options.system = {
      iso = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
      };

      patch = lib.mkOption {
        type = lib.types.attrsOf lib.types.package;
      };

      vm = lib.mkOption {
        type = lib.types.package;
      };
    };
  };
}
