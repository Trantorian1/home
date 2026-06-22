{
  system ? builtins.currentSystem,
  super ? import ./. {inherit system;},
  pkgs ? super.pkgs,
  ...
}:
pkgs.mkShellNoCC {
  packages = with pkgs; [
    npins
    nixos-facter
  ];
}
