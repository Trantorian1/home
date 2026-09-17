{...}: {
  programs.ghostty = {
    enable = true;
    settings = {
      shell-integration = "fish";
      cursor-style = "bar";
      keybind = [
        # Navigate splits
        "alt+left=goto_split:left"
        "alt+right=goto_split:right"
        "alt+down=goto_split:down"
        "alt+up=goto_split:up"

        # New splits
        "alt+shift+left=new_split:left"
        "alt+shift+right=new_split:right"
        "alt+shift+down=new_split:down"
        "alt+shift+up=new_split:up"
      ];
    };
  };
}
