{...}: {
  imports = [./options.nix];

  # Returns the structure used by `nix app`
  util.mkApp = drv: let
    name = drv.pname or drv.name;
    exePath = drv.passthru.exePath or "/bin/${name}";
  in {
    type = "app";
    program = "${drv}${exePath}";
    meta = drv.meta;
  };
}
