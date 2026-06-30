{lib, ...}: {
  imports = [
    ./discover.nix
    ./bootstrap.nix
  ];

  util.installer.mkCommonAttrs = attr:
    lib.attrsets.recursiveUpdate attr {
      system.stateVersion = "26.05";

      nixpkgs.hostPlatform = "x86_64-linux";

      # By default the system still pings `cache.nixos.org` when building a
      # derivation, even if it has all the necessary artifacts already available
      # locally. This setting disables ALL binary caches, so that the system will
      # only be able to use local data during the derivation process.
      nix.settings.substituters = lib.mkForce [];

      # We don't need to login, since both installation services require no user
      # interaction
      systemd.services."getty@tty1".enable = false;
    };
}
