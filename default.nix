{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  pkgs ?
    import sources.nixpkgs {
      inherit system;
      config = {};
      overrides = [];
    },
  ...
}: let
  module = pkgs.lib.evalModules {
    modules = [
      ({config, ...}: {config._module.args = {inherit pkgs;};})
      ./iso.nix
    ];
  };
in {
  inherit pkgs;
  inherit module;
}
