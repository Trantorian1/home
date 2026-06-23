{
  config,
  nixos,
  pkgs,
  lib,
  ...
}: {
  options = {
    iso = lib.mkOption {
      type = lib.types.package;
    };

    vm = lib.mkOption {
      type = lib.types.package;
    };
  };

  config = {
    iso = nixos.config.system.build.images.iso;

    vm = pkgs.writeShellApplication {
      name = "vm";
      runtimeInputs = with pkgs; [qemu];
      text = ''
        if [ ! -e drive.img ]; then
          qemu-img create -f qcow2 drive.img 40G
        fi

        qemu-system-x86_64 \
          -machine q35,accel=kvm:tcg \
          -cpu max \
          -m 16G \
          -smp 4 \
          -drive file=drive.img,format=qcow2,if=virtio \
          -nic user,model=virtio-net-pci \
          -cdrom ${config.iso}/iso/${config.iso.isoName}
      '';
    };
  };
}
