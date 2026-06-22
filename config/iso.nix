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
        qemu-system-x86_64 \
          -machine q35,accel=kvm:tcg \
          -cpu max \
          -m 8G \
          -smp 4 \
          -cdrom ${config.iso}/iso/${config.iso.isoName}
      '';
    };
  };
}
