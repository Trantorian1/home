#                         [ SYSTEM INSTALLATION ]
#
# System configurations used to generate reproducible, air-gaped installation
# media which bundled the nixos system described in `./configuration.nix`.
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
let
  common = lib: attr:
    lib.attrsets.recursiveUpdate attr {
      system.stateVersion = "26.05";

      # By default the system still pings `cache.nixos.org` when building a
      # derivation, even if it has all the necessary artifacts already available
      # locally. This setting disables ALL binary caches, so that the system will
      # only be able to use local data during the derivation process.
      nix.settings.substituters = lib.mkForce [];

      # We don't need to login, since both installation services require no user
      # interaction
      systemd.services."getty@tty1".enable = false;
    };
in {
  # = DISCOVER =
  #
  # Boots a minimal system configuration, generating a hardware report with
  # nixos-facter and nothing else.
  #
  #   This report is meant to be retrieved by the host so the final system
  #   configuration can be derived outside of the live iso. An ssh server is
  #   opened so that 'scp' can be used for this purpose.
  #
  #                                   . . .
  #
  # It would be an interesting exercise to have the discover step send the
  # resulting hardware scan back to the host automatically, perhaps by opening
  # an ssh server there instead of on the target hardware, though this will
  # require more forethought on how to handle secret keys to maintain secure
  # identification.
  discover = {
    pkgs,
    lib,
    ...
  }: let
    sources = import ./npins;
    nixpkgs = import sources.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
    };

    reportFiles = "/tmp/hardware-report";
  in
    common lib {
      users.users.nixos = {
        isNormalUser = true;
        extraGroups = ["wheel"];
        initialPassword = "test";
      };

      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PasswordAuthentication = true;
        };
      };

      systemd.services.hardware-report = {
        description = "Generate hardware report";

        wantedBy = ["multi-user.target"];
        conflicts = ["autovt@tty1.service"];

        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "tty";
          StandardError = "tty";
          TTYPath = "/dev/tty1";
        };

        path = with nixpkgs; [nixos-facter];

        script = ''
          echo ">>> Generating hardware config"
          mkdir -p ${reportFiles}
          nixos-facter -o ${reportFiles}/facter.json
          chown nixos:users ${reportFiles}/facter.json
        '';
      };
    };

  # = BOOTSTRAP =
  #
  # Fully offline automated installer which bootstraps the os state as described
  # in ./configuration.nix.
  #
  #   This requires the target hardware to be known, which can be done by
  #   retrieving the result of the hardware scan generated in the 'discover'
  #   step
  bootstrap = {
    pkgs,
    lib,
    ...
  }: let
    sources = import ./npins;
    nixpkgs = import sources.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
    };

    # The target system configuration, based off `./configuration.nix`, is being
    # built at derivation time on the HOST machine. The resulting attribute set
    # is automatically bundled into the 'bootstrap' configuration, which means
    # that at runtime the system only has to APPLY the configuration change, not
    # COMPUTE it.
    #
    # This pushes the burden of network impurities to such times as when the
    # 'bootstrap' iso is build, making it possible for the installation to be
    # entirely air-gaped.
    #
    #   Note that this requires for the target system's hardware to be known, so
    #   that nixos can configure essential system information such as which
    #   kernel modules to install. This is handled by the 'discover' step above.
    target = pkgs.nixos ./configuration.nix;

    toplevel = target.config.system.build.toplevel;
    diskoScript = target.config.system.build.diskoScript;

    dotFiles = "${target.config.users.users.trantorian.home}/.dotfiles";
  in
    common lib {
      systemd.services.auto-install = {
        description = "Auto-install NixOs system";

        wantedBy = ["multi-user.target"];
        conflicts = ["autovt@tty1.service"];

        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "tty";
          StandardError = "tty";
          TTYPath = "/dev/tty1";
        };

        path = with nixpkgs; [
          nix
          nixos-install-tools
        ];

        script = ''
          set -euo pipefail

          echo ">>> formatting + mounting"
          ${diskoScript}

          echo ">>> installing system"
          nixos-install \
            --system ${toplevel} \
            --root /mnt \
            --no-root-passwd \
            --no-channel-copy

          echo ">>> loading configuration"
          mkdir -p /mnt${dotFiles}
          cp -r --no-preserve=mode ${./.}/* /mnt${dotFiles}
          nixos-enter --root /mnt -c "chown -R trantorian:users ${dotFiles}"

          echo ">>> install complete; rebooting"
          systemctl reboot
        '';
      };
    };
}
