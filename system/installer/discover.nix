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
