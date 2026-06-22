{
  defaultSystems ? [
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
    "x86_64-linux"
  ],
}: rec {
  inherit defaultSystems;

  # eachSystem using defaultSystems
  eachDefaultSystem = eachSystem defaultSystems;

  # Builds a map from <attr>=value to <attr>.<system>=value for each system.
  eachSystem = eachSystemOp (
    # Merge outputs for each system.
    f: attrs: system: let
      ret = f system;
    in
      builtins.foldl' (
        attrs: key:
          attrs
          // {
            ${key} =
              (attrs.${key} or {})
              // {
                ${system} = ret.${key};
              };
          }
      )
      attrs (builtins.attrNames ret)
  );

  # Applies a merge operation accross systems.
  eachSystemOp = op: systems: f:
    builtins.foldl' (op f) {} (
      if !builtins ? currentSystem || builtins.elem builtins.currentSystem systems
      then systems
      else
        # Add the current system if the --impure flag is used.
        systems ++ [builtins.currentSystem]
    );

  # Returns the structure used by `nix app`
  mkApp = drv: let
    name = drv.pname or drv.name;
    exePath = drv.passthru.exePath or "/bin/${name}";
  in {
    type = "app";
    program = "${drv}${exePath}";
    meta = drv.meta;
  };
}
