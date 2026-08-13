# Kani is not in nixpkgs and cannot simply be built from source: `kani-driver`
# shells out to CBMC, a SAT solver and a set of Rust libraries which must be
# compiled by the *exact* nightly rustc that Kani links against. Upstream works
# around this by having the `kani` and `cargo-kani` binaries act as proxies
# which download a release bundle into `~/.kani` on first use -- something we
# cannot do from a read-only, offline Nix store.
#
# So we assemble that bundle ourselves instead:
#
#   1. `kaniHome` takes the upstream release bundle -- which carries CBMC,
#      kissat, goto-cc and the pre-compiled Kani libraries -- and patches its
#      binaries to link against nixpkgs' libraries.
#   2. `kani-compiler` and the `kani` / `cargo-kani` proxies are built from
#      source against the dated nightly toolchain Kani pins, taken from
#      `rust-overlay`.
#   3. The proxies are wrapped with `KANI_HOME` pointing at the bundle from (1),
#      so they consider Kani already set up and never try to download anything.
#
# Based on the packaging attempt documented in
# <https://discourse.nixos.org/t/packaging-kani-rust-verifier/43957> and its
# conclusion at <https://github.com/gleachkr/nix-tools/blob/main/kani/default.nix>.
{
  lib,
  # `pkgs.extend`. Kani needs a dated nightly toolchain, and there is no reason
  # to leak `rust-overlay` into the rest of the system's package set to get one.
  extend,
  stdenv,
  autoPatchelfHook,
  glibc,
  makeWrapper,
  rsync,
  rust-overlay,
  kani-repo,
  kani-tarball,
}: let
  # Must be kept in sync with the `kani-repo` and `kani-tarball` flake inputs.
  # `cargoHash` below has to be refreshed whenever this changes.
  version = "0.66.0";

  inherit (stdenv.hostPlatform) config;

  rustPkgs = extend rust-overlay.overlays.default;

  # The release bundle records the toolchain it was built with as
  # `nightly-<date>-<target triple>`. `kani-compiler` links against that
  # toolchain's `librustc_driver-<hash>.so`, so the two have to match exactly;
  # reading the date back out of the bundle keeps them from drifting apart on a
  # version bump.
  rustNightly =
    lib.removePrefix "nightly-"
    (lib.removeSuffix "-${config}" (lib.fileContents "${kani-tarball}/rust-toolchain-version"));

  toolchain = rustPkgs.rust-bin.nightly.${rustNightly}.default.override {
    extensions = [
      "llvm-tools"
      "rustc-dev"
      "rust-src"
      "rustfmt"
    ];
  };

  rustPlatform = rustPkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };

  # The release bundle, minus `kani-compiler`: the shipped binary keeps a
  # `DT_NEEDED` on `librustc_driver-<hash>.so` resolved through the rustup
  # toolchain it was built on, which `autoPatchelfHook` has no way of finding.
  # We build our own from source further down. Everything else in the bundle
  # only needs libc, libgcc_s, libm and libstdc++.
  kaniHome = stdenv.mkDerivation {
    pname = "kani-home";
    inherit version;

    # Already unpacked: `kani-tarball` is a `flake = false` tarball input.
    src = kani-tarball;
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs = [
      autoPatchelfHook
      rsync
    ];

    # `libstdc++` and `libgcc_s`, needed by CBMC and its tooling.
    buildInputs = [stdenv.cc.cc.lib];

    # `autoPatchelfHook` resolves this one on its own, but does not add it to
    # the runpath of the binaries it rewrites.
    runtimeDependencies = [glibc];

    installPhase = ''
      runHook preInstall
      rsync -a "$src/" "$out" --exclude kani-compiler
      runHook postInstall
    '';
  };
in
  rustPlatform.buildRustPackage {
    pname = "kani";
    inherit version;

    src = kani-repo;
    cargoHash = "sha256-XFuhaFqvpYhFDpvrH7wwPwjFbC7/TAqIl0F9+Eu8zUA=";

    nativeBuildInputs = [
      makeWrapper
      rsync
    ];

    # `kani-compiler`'s build script resolves the toolchain it links against as
    # `$RUSTUP_HOME/toolchains/$RUSTUP_TOOLCHAIN`. Pointing the latter at `..`
    # collapses that path back onto the toolchain's own store path, which is how
    # we get away without rustup inside the sandbox.
    env = {
      RUSTUP_HOME = "${toolchain}";
      RUSTUP_TOOLCHAIN = "..";
    };

    # The test suite drives a complete Kani installation, which does not exist
    # yet at this point in the build.
    doCheck = false;

    # Lay `$out/lib` out the way `cargo kani setup` would lay out `~/.kani`, so
    # the proxies find a complete installation and skip their download step.
    # Only `kani-compiler` is taken from our build: the rest of the bundle was
    # produced by the same upstream toolchain and is what the pre-compiled Kani
    # libraries were built against.
    postInstall = ''
      mkdir -p "$out/lib"
      rsync -a "${kaniHome}/" "$out/lib/kani-${version}" --perms --chmod=D+rw,F+rw
      cp "$out/bin/kani-compiler" "$out/lib/kani-${version}/bin/"
      ln -s "${toolchain}" "$out/lib/kani-${version}/toolchain"
    '';

    postFixup = ''
      wrapProgram "$out/bin/kani" --set KANI_HOME "$out/lib"
      wrapProgram "$out/bin/cargo-kani" --set KANI_HOME "$out/lib"
    '';

    meta = {
      description = "Bit-precise model checker for Rust";
      homepage = "https://github.com/model-checking/kani";
      license = with lib.licenses; [
        mit
        asl20
      ];
      mainProgram = "kani";
      # The release bundle we graft in is only published for a handful of
      # targets, and we only ever consume the linux one.
      platforms = ["x86_64-linux"];
    };
  }
