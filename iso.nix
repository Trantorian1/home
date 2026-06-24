{
  config,
  pkgs,
  lib,
  ...
}: let
  installer = import ./installer.nix;
  discover = pkgs.nixos installer.discover;
  bootstrap = pkgs.nixos installer.bootstrap;
in {
  options = {
    discover = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    iso = lib.mkOption {
      type = lib.types.package;
    };

    vm = lib.mkOption {
      type = lib.types.package;
    };
  };

  config = {
    # discover = true;

    iso =
      if config.discover
      then discover.config.system.build.images.iso
      else bootstrap.config.system.build.images.iso;

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
          -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 \
          -cdrom ${config.iso}/iso/${config.iso.isoName}
      '';
    };
  };
}
