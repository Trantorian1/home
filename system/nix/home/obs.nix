{pkgs, ...}: {
  # Replicates the pinned HM programs.obs-studio module (rev 6750249) exactly:
  # its finalPackage is pkgs.wrapOBS with obs-studio and the plugin list — a
  # symlinkJoin whose `obs` binary is wrapped to point OBS_PLUGINS_PATH at the
  # joined plugin dir. Hjem has no program module, so the wrapped package goes
  # straight into `packages`.
  packages = [
    (pkgs.wrapOBS.override {obs-studio = pkgs.obs-studio;} {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    })
  ];
}
