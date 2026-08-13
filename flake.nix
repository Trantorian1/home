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

    home-manager = {
      # CAUTION: this needs to be kept in sync with the version of `nixpkgs`
      # being used
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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

    # Kani pins a dated nightly toolchain, which nixpkgs has no way of
    # providing. See `system/nix/home/kani`.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Kani is built from source, but the CBMC toolchain and pre-compiled Kani
    # libraries it drives are grafted in from the matching release bundle. Both
    # inputs need to stay in sync with the `version` in
    # `system/nix/home/kani/package.nix`.
    kani-repo = {
      url = "git+https://github.com/model-checking/kani?ref=refs/tags/kani-0.66.0&rev=b37b90f4081da4e4194b1c8a728c117128d5e06e&submodules=1";
      flake = false;
    };

    kani-tarball = {
      url = "https://github.com/model-checking/kani/releases/download/kani-0.66.0/kani-0.66.0-x86_64-unknown-linux-gnu.tar.gz";
      flake = false;
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        ./lib
        ./system
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            # nix
            nixos-facter
            nix-index
            nurl

            # iso remastering
            libisoburn

            # crypto
            age
            sops
          ];
        };
      };
    };
}
