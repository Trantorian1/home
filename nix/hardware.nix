{lib, ...}: {
  config.hardware.facter.reportPath = lib.mkIf (builtins.pathExists ./facter.json) ./facter.json;
}
