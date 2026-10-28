{pkgs, ...}: let
  path = "$HOME/.config/opencode";
  name = "opencode.json";
  opencode = pkgs.writeTextFile {
    inherit name;
    text = builtins.readFile ./opencode.json;
  };
in {
  system.userActivationScripts.opencode = {
    text = ''
      mkdir -p ${path};
      cp -r ${opencode} ${path}/${name};
    '';
  };
}
