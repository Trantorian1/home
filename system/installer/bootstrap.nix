#                                 [ BOOTSTRAP ]
#
# Fully offline automated installer which bootstraps the os state as described
# in ./configuration.nix.
#
#   This requires the target hardware to be known, which can be done by
#   retrieving the result of the hardware scan generated in the 'discover' step
{
  self,
  config,
  inputs,
  ...
}: let
  util = config.util;
in {
  flake.nixosModules.bootstrap = let
    # The target system configuration, is being built at derivation time on the
    # HOST machine. The resulting attribute set is automatically bundled into
    # the 'bootstrap' configuration, which means that at runtime the system only
    # has to APPLY the configuration change, not COMPUTE it.
    #
    # This pushes the burden of network impurities to such times as when the
    # 'bootstrap' iso is build, making it possible for the installation to be
    # entirely air-gaped.
    #
    #   Note that this requires that the target system's hardware be known, so
    #   that nixos can configure essential system information such as which
    #   kernel modules to install. This is handled by the 'discover' step prior.
    target = config.installer.targetSystem;

    toplevel = target.config.system.build.toplevel;
    diskoScript = target.config.system.build.diskoScript;

    dotFiles = "${target.config.users.users.trantorian.home}/.dotfiles";
    sopsFiles = "${target.config.users.users.trantorian.home}/.config/sops/age";
  in
    {
      config,
      pkgs,
      lib,
      ...
    }:
      util.installer.mkCommonAttrs {
        systemd.services.auto-install = {
          description = "Auto-install NixOs system";

          wantedBy = ["multi-user.target"];
          conflicts = ["autovt@tty1.service"];

          serviceConfig = {
            Type = "oneshot";
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "tty";
            TTYPath = "/dev/tty1";
          };

          path = with pkgs; [
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
            cp -r --no-preserve=mode ${../../.}/* /mnt${dotFiles}
            nixos-enter --root /mnt -c "chown -R trantorian:users ${dotFiles}"

            echo ">>> loading secrets"
            mkdir -p /mnt${sopsFiles}
            cp /iso/etc/keys.txt /mnt${sopsFiles}

            echo ">>> install complete; rebooting"
            systemctl reboot
          '';
        };
      };

  flake.nixosConfigurations.bootstrap = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.bootstrap];
  };
}
