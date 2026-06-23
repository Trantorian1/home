{
  pkgs,
  lib,
  ...
}: let
  sources = import ./npins;
  nixpkgs = import sources.nixpkgs {inherit (pkgs.stdenv.hostPlatform) system;};

  target = pkgs.nixos ./configuration.nix;
  toplevel = target.config.system.build.toplevel;
  diskoScript = target.config.system.build.diskoScript;

  confFiles = "/tmp/.dotfiles";
  dotFiles = "${target.config.users.users.trantorian.home}/.dotfiles";
in {
  nix.settings.substituters = lib.mkForce [];

  system.extraDependencies = [toplevel];

  systemd.services."getty@tty1".enable = false;

  systemd.services.autoinstall = {
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
      nixos-facter
    ];

    script = ''
      set -euo pipefail

      echo ">>> formatting + mounting"
      ${diskoScript}

      echo ">>> loading configuration"
      mkdir -p ${confFiles}
      cp -r --no-preserve=mode ${./.}/* ${confFiles}

      echo ">>> generating hardware report"
      nixos-facter -o ${confFiles}/nix/facter.json

      echo ">>> building system"
      nix-build ${confFiles}/install-system.nix -o /tmp/system

      echo ">>> installing system"
      nixos-install \
        --system /tmp/system \
        --root /mnt \
        --no-root-passwd \
        --no-channel-copy
      cp -r ${confFiles}/* ${dotFiles}

      echo ">>> install complete; rebooting"
      systemctl reboot
    '';
  };

  system.stateVersion = "26.05";
}
