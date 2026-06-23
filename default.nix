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
  nixos = pkgs.nixos ./installer.nix;
  module = pkgs.lib.evalModules {
    modules = [
      ({config, ...}: {config._module.args = {inherit pkgs nixos;};})
      ./iso.nix
    ];
  };
in {
  inherit pkgs;
  inherit module;
}
