{...}: {
  programs.fish = {
    enable = true;
    shellAliases = {
      e = "exit";
    };
    interactiveShellInit = ''
      # Disable the default greeting
      set fish_greeting
    '';
  };
}
