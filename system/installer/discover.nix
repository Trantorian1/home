#                               [ DISCOVER ]
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
{
  self,
  config,
  inputs,
  ...
}: let
  util = config.util;
in {
  flake.nixosModules.discover = let
    reportFiles = "/tmp/hardware-report";
  in
    {
      config,
      pkgs,
      lib,
      ...
    }:
      util.installer.mkCommonAttrs {
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

          path = [pkgs.nixos-facter];

          script = ''
            echo ">>> Generating hardware config"
            mkdir -p ${reportFiles}
            nixos-facter -o ${reportFiles}/facter.json
            chown nixos:users ${reportFiles}/facter.json

            echo ">>> List drives"
            ls -l /dev/disk/by-path
          '';
        };
      };

  flake.nixosConfigurations.discover = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.discover];
  };
}
