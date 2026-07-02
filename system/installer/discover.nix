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
  inputs,
  config,
  ...
}: let
  util = config.util;
in {
  flake.nixosModules.discover = let
    reportFiles = "/tmp/hardware-report";
  in
    {
      modulesPath,
      config,
      pkgs,
      lib,
      ...
    }:
      util.installer.mkCommonAttrs modulesPath {
        image.modules.iso = {...}: {
          image.baseName = lib.mkForce "discover";
        };

        # Opens an ssh server so the result of the hardware scan can be
        # retrieved via scp
        services.openssh = {
          enable = true;
          openFirewall = true;
          settings = {
            AllowUsers = ["nixos"];
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };

          # By default, openssh will re-generate new ssh host keys on startup.
          # Instead, we use sops to set a stable ssh identity. This is useful
          # when connecting several times to the same address, as it avoids key
          # mismatch errors.
          generateHostKeys = false;
          hostKeys = [
            {
              path = config.sops.secrets."host/qemu".path;
              type = "rsa";
            }
          ];
        };

        # WARNING: the age private key used by sops to decrypt secrets must
        # NEVER be copied over to the nix store, as from there it can be read
        # by any other derivation! To avoid this, we reference the key by it's
        # absolute path in the final ISO, which does not copy it as part of the
        # derivation process. Instead, `/iso/etc/keys.txt` has to be manually
        # patched into the 'discover' installation media via `patch-discover`.
        sops.age = {
          keyFile = "/iso/etc/keys.txt";
          generateKey = false;
        };

        sops.secrets."host/qemu" = {
          sopsFile = ../../secrets/ssh.dev.yaml;
        };

        # A user, other than root, which we can connect to via ssh.
        # Authentication is done by keypairs only.
        users.users.nixos = {
          isNormalUser = true;
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcTpzrd1LxnLLZcCCbvQSW12xweg3tldxbr1KvZxoFLMHzwHfIb8HrbHplo5Q0JcP/MJSP8E5GZ79BK/u1pej8AtiI3luPhvCn56zxRvffwJ6WZ1hGDya7rUXkYDp/PwAGxBy1wCAb7scxfeH/A1NraL4x+yN3M8Ush2bmAKKpTCMxTwrshyiDEJqmo5tBB92pJvcvUPuuKILfhvUoqROkdHQ+rnltRgJg9AZcYjIdiqfiTk950YsvVq91od0CWEFCWTtBHyS6XETXT7wNVW8dMjGDw+FV0la23Fe53OM7qty8ayZoJ0lfl0yYcfsQ7wd5WSNnXag04y+f3a8EHI2WPH6TdfSc+slAJvWygpzGILlQKVSzbwl5KA7Vz59coGoINkih+kMIm5bAM/twp/yBQy/hv45sPNL5HADEeYglYJzv316ocVx9ag0wXfiSWuTZrzz/j2RTc0mjHlJATRREAY/JZmQUGU0sZkedxyFZYweONb6kvcQmBg62bwhVc5villvByzrrtSS92BmLZFUmbBUoYyEPOSrGN+ttlpjOo7jc646Y/jhERW/01k64dCv5MhkAmikSeGBHBQkbH6AC6A86sQSQhLDw0oeeOvqebMCQmAo5cc98YRCGQ33R4Emp8iqJmzZmyclFJ+KOl5yG40Db0G2GuoP5W32qPwX6Aw== trantorian@nixos"
          ];
        };

        # Actual hardware report service. TTY login is disabled, as user login
        # is supposed to happen over ssh. Stable disk paths are also listed in
        # order to configure 'disko' across a fleet of similar machines.
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
