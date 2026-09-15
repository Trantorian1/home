{...}: {
  boot.tmp.cleanOnBoot = true;

  preservation = {
    enable = true;

    preserveAt."/persistent" = {
      files = [
        # auto-generated machine ID
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];

      directories = [
        "/var/lib/systemd/timers"
        # NixOS user state
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/bluetooth"
        "/etc/NetworkManager/system-connections"
      ];

      users.dev = {
        directories = [
          ".dotfiles"

          ".local/share/keyrings"
          ".ssh"

          ".config/sops/age"
          ".config/discord"
          ".config/zen"
          ".config/Proton Mail"
          ".config/BambuStudio"

          # Unlosth
          ".unsloth"
          ".cache/huggingface"
          ".cache/unsloth"
          ".local/share/ai.unsloth.studio"
          ".local/share/uv"
          ".cache/uv"

          # Steam
          ".steam"
          ".local/share/Steam"

          "Documents"
          "Music"
          "Pictures"
          "Video"
        ];
      };
    };
  };

  # systemd-machine-id-commit.service would fail, but it is not relevant
  # in this specific setup for a persistent machine-id so we disable it
  systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
}
