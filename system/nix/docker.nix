{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;

    rootless = {
      enable = true;

      daemon.settings = {
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
