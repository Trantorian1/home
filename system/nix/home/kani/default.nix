{
  rust-overlay,
  kani-repo,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.callPackage ./package.nix {
      inherit rust-overlay kani-repo;
    })
  ];
}
