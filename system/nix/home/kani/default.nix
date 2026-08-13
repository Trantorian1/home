{
  rust-overlay,
  kani-repo,
  kani-tarball,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.callPackage ./package.nix {
      inherit rust-overlay kani-repo kani-tarball;
    })
  ];
}
