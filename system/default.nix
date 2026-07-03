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
    # All the systems which are available to build installation media from.
    # Other options are derived from this attribute set.
    system.configuration = {
      qemu = self.nixosConfigurations.qemu;
      desktop = self.nixosConfigurations.desktop;
      laptop = self.nixosConfigurations.laptop;
    };

    # System installer configurations.
    #
    # This includes the 'discover' installer, which is used for the initial
    # hardware scan on a new system, as well as the bootstrapped version of each
    # final system configuration.
    system.installer =
      {
        discover = self.nixosConfigurations.discover;
      }
      // builtins.mapAttrs
      (_name: target: util.installer.mkBoostrap target pkgs)
      config.system.configuration;

    # Un-patched iso for each installation media.
    #
    # Each iso has to be manually patched with `nix run .#patch` to populate it
    # with the required secret keys before being run.
    packages =
      builtins.mapAttrs
      (_name: bootstrap: bootstrap.config.system.build.images.iso)
      config.system.installer;

    apps = {
      patch = util.mkApp (pkgs.writeShellApplication {
        name = "patch";
        meta.description = "Patches an iso with secret keys outside of the nix store environment";

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

          echo "Copying over iso"
          cp "$1" "$iso"

          xorriso -dev "$iso"       `# loads the iso`                       \
            -boot_image any replay  `# needed to preserve boot information` \
            -map "$2" /etc/keys.txt `# copies the secret into the iso fs`   \
            -commit
        '';
      });

      vm = util.mkApp (pkgs.writeShellApplication {
        name = "vm";
        meta.description = "Runs a patched iso in a qemu vm";

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
            -device virtio-vga \
            -display gtk \
            -device virtio-serial-pci \
            -chardev qemu-vdagent,id=vdagent,name=vdagent,clipboard=on \
            -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
            -cdrom "$1"
        '';
      });
    };
  };
}
