{config, ...}: let
  util = config.util;
in {
  imports = [
    ./installer
    ./options.nix
    ./config.nix
    ./desktop.nix
  ];

  perSystem = {
    self',
    config,
    lib,
    ...
  }: {
    packages = config.system.iso;
    apps = builtins.mapAttrs (name: vm: util.mkApp vm) config.system.vm;
  };
}
