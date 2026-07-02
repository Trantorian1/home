{
  self,
  config,
  ...
}: let
  util = config.util;
in {
  imports = [
    ./installer
    ./options.nix
    ./configuration.nix
  ];

  perSystem = {
    self',
    config,
    pkgs,
    lib,
    ...
  }: {
    system.configuration = {
      qemu = self.nixosConfigurations.qemu;
      desktop = self.nixosConfigurations.desktop;
    };

    system.installer =
      {
        discover = self.nixosConfigurations.discover;
      }
      // builtins.mapAttrs
      (_name: target: util.installer.mkBoostrap target pkgs)
      config.system.configuration;

    packages =
      builtins.mapAttrs
      (_name: bootstrap: bootstrap.config.system.build.images.iso)
      config.system.installer;

    apps = {
      patch = util.mkApp (pkgs.writeShellApplication {
        name = "patch";
        runtimeInputs = with pkgs; [busybox libisoburn];
        text = ''
          if [ "$#" -ne 2 ]; then
            echo "Usage: patch <iso> <secret>"
          fi

          name=$(basename "$1")
          iso="./patched-$name"

          if [ -e "$iso" ]; then
            echo "Removing stale iso"
            rm "$iso"
          fi

          xorriso -indev "$1"       `# loads the iso`                       \
            -outdev "$iso"                                                  \
            -boot_image any replay  `# needed to preserve boot information` \
            -map "$2" /etc/keys.txt `# copies the secret into the iso fs`   \
            -commit
        '';
      });

      vm = util.mkApp (pkgs.writeShellApplication {
        name = "vm";
        runtimeInputs = with pkgs; [qemu];
        text = ''
          if [ "$#" -ne 1 ]; then
            echo "Usage: vm <iso>"
            exit 1
          fi

          if [ ! -e drive.img ]; then
            qemu-img create -f qcow2 drive.img 40G
          fi

          qemu-system-x86_64 \
            -machine q35,accel=kvm:tcg \
            -cpu max \
            -m 16G \
            -smp 4 \
            -drive file=drive.img,format=qcow2,if=virtio \
            -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 \
            -cdrom "$1"
        '';
      });
    };
  };
}
