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
  nixos = pkgs.nixos ./config/configuration.nix;
  module = pkgs.lib.evalModules {
    modules = [
      ({config, ...}: {config._module.args = {inherit pkgs nixos;};})
      ./config/iso.nix
    ];
  };
in {
  inherit pkgs;
  inherit module;
}
