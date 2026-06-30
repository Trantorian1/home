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

    system.vm = builtins.mapAttrs (name: iso:
      pkgs.writeShellApplication {
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
            -cdrom ${iso}/iso/${iso.isoName}
        '';
      })
    config.system.iso;

    packages = config.system.iso;

    apps = builtins.mapAttrs (name: vm: util.mkApp vm) config.system.vm;
  };
}
