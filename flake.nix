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

    # Kani is built from source off `main` rather than from a release, so that
    # experimental features which have not made a stable release yet are
    # available.
    #
    # The revision is pinned here rather than left to float on `main`, because
    # the vendored dependency hashes in `system/nix/home/kani/package.nix` are
    # tied to this exact tree: letting the input move on its own would leave
    # them stale. Bumping Kani means moving this `rev` and refreshing those
    # hashes together. The toolchain follows the checkout on its own.
    kani-repo = {
      url = "github:model-checking/kani/2bf550f91c76e6ef439f742cb7963f26d2925678";
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
