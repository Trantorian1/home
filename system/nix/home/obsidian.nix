{pkgs, ...}: {
  # HM's programs.obsidian with only `enable = true` installed the obsidian
  # package plus an activation hook that merged a boilerplate obsidian.json
  # (empty vaults, updateDisabled = true, cli = false) into
  # ~/.config/obsidian/. No vaults or settings are configured here, so per
  # the plan this module carries over the package only; the generated file
  # contained no user data.
  packages = [pkgs.obsidian];
}
