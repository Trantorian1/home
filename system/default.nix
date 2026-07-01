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

  installer.targetSystem = self.nixosConfigurations.qemu;

  perSystem = {
    self',
    config,
    pkgs,
    lib,
    ...
  }: {
    system.iso = {
      discover = self.nixosConfigurations.discover.config.system.build.images.iso;
      bootstrap = self.nixosConfigurations.bootstrap.config.system.build.images.iso;
    };

    system.patch = lib.attrsets.mapAttrs' (name: iso:
      lib.attrsets.nameValuePair "patch-${name}" (pkgs.writeShellApplication {
        name = "patch-${name}";
        runtimeInputs = with pkgs; [libisoburn];
        text = ''
          if [ "$#" -ne 1 ]; then
            echo "Usage: patch-${name} <secret>"
          fi

          iso=./patched-${name}.iso

          if [ -e $iso ]; then
            echo "Removing stale iso"
            rm $iso
          fi

          xorriso -indev ${iso}/iso/${iso.isoName} `# loads the iso`                       \
            -outdev $iso                                                                   \
            -boot_image any replay                 `# needed to preserve boot information` \
            -map "$1" /etc/hello.txt               `# copies the secret into the iso fs`   \
            -commit
        '';
      }))
    config.system.iso;

    system.vm = pkgs.writeShellApplication {
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
    };

    packages = config.system.patch;

    apps.vm = util.mkApp config.system.vm;
  };
}
