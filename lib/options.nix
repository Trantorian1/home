{lib, ...}: {
  options.util = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
  };
}
