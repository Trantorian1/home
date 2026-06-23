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
in {
  nix.settings.substituters = lib.mkForce [];

  # Disable tty login: we are only
  systemd.services."getty@".enable = false;
  systemd.services."autovt@".enable = false;

  systemd.services.autoinstall = {
    description = "Auto-install NixOs system";

    wantedBy = ["multi-user.target"];
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

      echo ">>> install complete; rebooting"
      systemctl reboot
    '';
  };

  system.stateVersion = "26.05";
}
