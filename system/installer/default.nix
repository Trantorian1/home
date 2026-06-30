#                         [ SYSTEM INSTALLATION ]
#
# System configurations used to generate reproducible, air-gaped installation
# media which bundled the nixos system described in `configuration.nix`.
#
# Installation takes place in two steps:
#
#   1. In the 'discover' step, a hardware scan is performed which is stored to
#      `/tmp/hardware-report/facter.json`. This file is then copied to the host
#      machine so that it can be used in the next step.
#
#   2. In the `bootstrap` step, this hardware information is used to pre-compute
#      a derivation of the desired system configuration. This derivation is then
#      loaded into a minimal iso and applied, along with any drive partitioning
#      associated to it.
#
# The target system is then rebooted into the newly applied configuration.
{lib, ...}: {
  imports = [
    ./options.nix
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
