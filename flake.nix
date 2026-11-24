{
  description = "Home configuration with support for custom automated offline installers";

  inputs = {
    nixpkgs = {
      url = "github:NixOs/nixpkgs/nixos-unstable";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    disko = {
      url = "github:nix-community/disko/v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    unsloth = {
      url = "github:trantorian1/unsloth-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation = {
      url = "github:nix-community/preservation";
    };

    rv = {
      url = "github:trantorian1/rv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode-sandbox = {
      url = "github:OpencodeSandbox/opencode-sandbox?ref=feat/opencodev2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        ./lib
        ./system
      ];

      perSystem = {
        inputs',
        self',
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        packages = rec {
          sandbox = inputs'.opencode-sandbox.packages.sandbox.override {
            opencode-sandbox = {
              git.remote.url = "https://github.com/Trantorian1/home.git";
              git.shutdown.pushOnExit = false;
              git.withLocalChanges = true;

              env.extend = [env];
              opencode.config.mountHomeConfig = true;
              forwardPorts = [8888];
            };
          };

          env = pkgs.buildEnv {
            name = "devenv";
            paths = with pkgs; [
              # nix
              nixos-facter
              nix-index
              nurl
              self'.formatter

              # iso remastering
              libisoburn

              # crypto
              age
              sops
            ];
          };
        };

        devShells.default = pkgs.mkShellNoCC {
          packages = [self'.packages.env];
        };
      };
    };
}
