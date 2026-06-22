{
  description = "A very basic flake";

  outputs = {self, ...}: let
    util = import ./lib/util.nix {};
  in
    util.eachDefaultSystem (
      system: let
        super = import ./. {inherit system;};
        shell = import ./shell.nix {inherit system;};

        inherit (super) pkgs;
      in {
        formatter = pkgs.alejandra;

        packages = rec {
          inherit (super.module.config) iso vm;

          default = vm;
        };

        apps = rec {
          iso = util.mkApp self.packages.${system}.iso;
          vm = util.mkApp self.packages.${system}.vm;

          default = vm;
        };

        devShells = rec {
          inherit shell;

          default = shell;
        };
      }
    );
}
