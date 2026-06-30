{
  self,
  config,
  inputs,
  ...
}: let
  util = config.util;
in {
  flake.nixosModules.bootstrap = let
    target = self.nixosConfigurations.desktop;

    toplevel = target.config.system.build.toplevel;
    diskoScript = target.config.system.build.diskoScript;

    dotFiles = "${target.config.users.users.trantorian.home}/.dotfiles";
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

            echo ">>> install complete; rebooting"
            systemctl reboot
          '';
        };
      };

  flake.nixosConfigurations.bootstrap = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.bootstrap];
  };
}
