{
  discover = {
    pkgs,
    lib,
    ...
  }: let
    sources = import ./npins;
    nixpkgs = import sources.nixpkgs {inherit (pkgs.stdenv.hostPlatform) system;};

    reportFiles = "/tmp/hardware-report";
  in {
    nix.settings.substituters = lib.mkForce [];

    users.users.nixos = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      initialPassword = "test";
    };

    services.getty.autologinUser = "nixos";

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

      path = with nixpkgs; [nixos-facter];

      script = ''
        echo ">>> Generating hardware config"
        mkdir -p ${reportFiles}
        nixos-facter -o ${reportFiles}/facter.json
        chown nixos:users ${reportFiles}/facter.json
      '';
    };
  };

  bootstrap = {
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

    systemd.services."getty@tty1".enable = false;

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

        echo ">>> loading configuration"
        mkdir -p ${confFiles}
        cp -r --no-preserve=mode ${./.}/* ${confFiles}

        echo ">>> installing system"
        nixos-install \
          --system ${toplevel} \
          --root /mnt \
          --no-root-passwd \
          --no-channel-copy

        mkdir -p ${dotFiles}
        cp -r ${confFiles}/* ${dotFiles}

        echo ">>> install complete; rebooting"
        systemctl reboot
      '';
    };

    system.stateVersion = "26.05";
  };
}
