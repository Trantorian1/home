{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;

    rootless = {
      enable = true;
      setSocketVariable = true;

      daemon.settings = {
        default-runtime = "runsc";
        runtimes = {
          runsc = {
            path = "${pkgs.gvisor}/bin/runsc";
            runtimeArgs = ["--ignore-cgroups"];
          };
        };
      };
    };

    autoPrune = {
      enable = true;
      dates = "daily";
      persistent = true;
    };
  };
}
