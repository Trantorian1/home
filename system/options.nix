{lib, ...}: {
  perSystem = {...}: let
    nixosConfiguration = lib.mkOptionType {
      name = "nixosConfiguration";
      check = x: x._type or null == "configuration" && x.class or null == "nixos";
      merge = lib.options.mergeUniqueOption {
        message =
          "an evaluated NixOS configuration cannot be merged across definitions"
          + "; use extendModules at the definition site instead.";
      };
    };
  in {
    options.system = {
      configuration = lib.mkOption {
        type = lib.types.attrsOf nixosConfiguration;
      };

      installer = lib.mkOption {
        type = lib.types.attrsOf nixosConfiguration;
      };
    };
  };
}
