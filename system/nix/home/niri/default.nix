{pkgs, ...}: {
  # Hjem's equivalent of HM's `xdg.configFile` is `xdg.config.files`
  # (relative to $HOME/.config by default).
  xdg.config.files."niri/config.kdl".source =
    pkgs.runCommand "niri-config-checked"
    {
      nativeBuildInputs = [pkgs.niri];
    }
    ''
      niri validate --config ${./config.kdl}
      cp ${./config.kdl} $out
    '';
}
