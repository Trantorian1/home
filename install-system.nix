let
  sources = import ./npins;
  system = builtins.currentSystem;
  pkgs = import sources.nixpkgs {inherit system;};
  withHardware = pkgs.nixos [
    ./configuration.nix
    {
      config.hardware.facter.reportPath = ./nix/facter.json;
    }
  ];
in
  withHardware.config.system.build.toplevel
