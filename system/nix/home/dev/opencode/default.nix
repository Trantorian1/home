{pkgs, ...}: let
  path = "$HOME/.config/opencode";
  name = "opencode.jsonc";
  opencode = pkgs.writeTextFile {
    inherit name;
    text = builtins.readFile ./opencode.jsonc;
  };
in {
  system.userActivationScripts.opencode = {
    text = ''
      mkdir -p ${path};
      cp -r ${opencode} ${path}/${name};
    '';
  };
}
