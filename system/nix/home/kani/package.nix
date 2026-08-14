# Kani built from source, off `main`, so that experimental features (loop
# decrease contracts and friends) that have not made a stable release yet are
# available.
#
# Kani is not in nixpkgs, and its own instructions assume a rustup toolchain and
# a writable `~/.kani`. What upstream's `cargo build-dev` produces is a sysroot
# under `target/kani` laid out exactly like the release bundle, so the work here
# is to run that build in the sandbox and then install the result:
#
#   1. The toolchain comes from `rust-overlay`, read straight out of the
#      checkout's `rust-toolchain.toml` -- Kani links against `rustc_driver`, so
#      the nightly has to match the source exactly.
#   2. `cargo build-dev` builds the binaries and then compiles Kani's libraries
#      against the standard library with `-Z build-std`. That pulls in crates
#      from `rust-src`'s own lockfile, which is why the vendor tree below is a
#      merge of two.
#   3. CBMC and kissat come from nixpkgs rather than a downloaded bundle, and
#      are linked into the sysroot's `bin` where `kani-driver` looks for them.
#   4. The `kani` / `cargo-kani` proxies are wrapped with `KANI_HOME` pointing at
#      that sysroot, so they consider Kani set up and never try to download it.
#
# Bumping Kani is `nix flake update kani-repo`, plus refreshing `cargoHash`.
{
  lib,
  # `pkgs.extend`, used to apply `rust-overlay` locally: Kani needs a dated
  # nightly toolchain and there is no reason to leak that into the system's
  # package set.
  extend,
  stdenv,
  runCommand,
  cbmc,
  kissat,
  makeWrapper,
  rust-overlay,
  kani-repo,
}: let
  inherit (stdenv.hostPlatform) config;

  # The `kani-verifier` proxies resolve their installation as
  # `$KANI_HOME/kani-<version>`, where the version is baked in at compile time
  # from the crate manifest. Read it from the same manifest so the layout we
  # install always matches what they will go looking for.
  kaniVersion = (lib.importTOML "${kani-repo}/Cargo.toml").package.version;

  # `main` is a moving target, so identify the build by the revision's date on
  # top of the version it is working towards.
  srcDate = let
    d = kani-repo.lastModifiedDate;
  in "${lib.substring 0 4 d}-${lib.substring 4 2 d}-${lib.substring 6 2 d}";

  version = "${kaniVersion}-unstable-${srcDate}";

  rustPkgs = extend rust-overlay.overlays.default;

  # Kani pins its nightly in `rust-toolchain.toml` and links against that exact
  # `rustc_driver`; taking the toolchain from the file means it follows the
  # source across bumps instead of having to be tracked by hand.
  toolchainChannel = (lib.importTOML "${kani-repo}/rust-toolchain.toml").toolchain.channel;
  toolchain = rustPkgs.rust-bin.fromRustupToolchainFile "${kani-repo}/rust-toolchain.toml";

  rustPlatform = rustPkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };

  kaniVendor = rustPlatform.fetchCargoVendor {
    name = "kani-${version}";
    src = kani-repo;
    hash = "sha256-BN4OnNPOQ2nOFtKcZrA+aDFD7jkVIxEP78boOSg9gCU=";
  };

  # `-Z build-std` recompiles the standard library, whose dependencies live in
  # `rust-src`'s lockfile rather than Kani's.
  stdVendor = rustPlatform.fetchCargoVendor {
    name = "rust-src-${toolchainChannel}";
    src = "${toolchain}/lib/rustlib/src/rust/library";
    hash = "sha256-5oJ/mtsJW0R3F7jgxafP23+WMLkyMKu10De5WIzb7Ro=";
  };

  # Cargo can only replace `crates-io` with one directory source, so the two
  # vendor trees have to be flattened into a single one. Kani's is the base:
  # its `Cargo.lock` is the one the setup hook diffs against the source, and it
  # is the one carrying git sources.
  vendor = runCommand "kani-${version}-vendor-merged" {} ''
    cp -a ${kaniVendor} $out
    chmod -R u+w $out
    for crate in ${stdVendor}/source-registry-0/*; do
      dest="$out/source-registry-0/$(basename "$crate")"
      # Same crate and version from crates.io either way, so first one wins.
      [ -e "$dest" ] || cp -a "$crate" "$dest"
    done
  '';
in
  rustPlatform.buildRustPackage {
    pname = "kani";
    inherit version;

    src = kani-repo;
    cargoDeps = vendor;

    nativeBuildInputs = [makeWrapper];

    # `kani-compiler`'s build script resolves the toolchain it links against as
    # `$RUSTUP_HOME/toolchains/$RUSTUP_TOOLCHAIN`. Pointing the latter at `..`
    # collapses that path back onto the toolchain's own store path, which is how
    # we get away without rustup inside the sandbox.
    env = {
      RUSTUP_HOME = "${toolchain}";
      RUSTUP_TOOLCHAIN = "..";
      CARGO_NET_OFFLINE = "true";
    };

    # `cargo build-dev` is upstream's own build driver: it builds the binaries
    # into `target/kani/bin`, then uses the freshly built `kani-compiler` to
    # compile Kani's libraries and the standard library into the sysroot.
    buildPhase = ''
      runHook preBuild
      cargo build-dev -- --release
      cargo build --release -p kani-cov
      runHook postBuild
    '';

    # The regression suite drives a complete Kani installation and a set of
    # solvers we do not have here.
    doCheck = false;

    # Lay the sysroot out where the proxies expect to find it, matching the
    # release bundle's structure.
    installPhase = ''
      runHook preInstall

      home="$out/lib/kani-${kaniVersion}"
      mkdir -p "$home" "$out/bin"

      cp -r target/kani/bin "$home/bin"
      cp -r target/kani/lib "$home/lib"
      cp -r target/kani/playback "$home/playback"
      cp -r target/kani/no_core "$home/no_core"
      install -Dm755 target/release/kani-cov "$home/bin/kani-cov"

      # `kani-driver` reads `library/kani/kani_lib.c` out of the installation.
      mkdir -p "$home/library"
      cp -r library/kani library/kani_macros library/std "$home/library/"

      # The proxies prepend this directory to `PATH` before handing off to
      # `kani-driver`, which is how the CPROVER tools get found.
      for tool in ${cbmc}/bin/* ${kissat}/bin/*; do
        ln -s "$tool" "$home/bin/$(basename "$tool")"
      done

      # `kani-driver` runs `cargo` out of this symlink rather than going through
      # rustup, and reads the channel back from `rust-toolchain-version`.
      ln -s "${toolchain}" "$home/toolchain"
      printf '%s' "${toolchainChannel}-${config}" > "$home/rust-toolchain-version"

      install -Dm755 target/kani/bin/kani "$out/bin/kani"
      install -Dm755 target/kani/bin/cargo-kani "$out/bin/cargo-kani"

      runHook postInstall
    '';

    postFixup = ''
      wrapProgram "$out/bin/kani" --set KANI_HOME "$out/lib"
      wrapProgram "$out/bin/cargo-kani" --set KANI_HOME "$out/lib"
    '';

    meta = {
      description = "Bit-precise model checker for Rust, built from the development branch";
      homepage = "https://github.com/model-checking/kani";
      license = with lib.licenses; [
        mit
        asl20
      ];
      mainProgram = "kani";
      platforms = ["x86_64-linux"];
    };
  }
