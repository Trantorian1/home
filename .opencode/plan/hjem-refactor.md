# Refactor Home-Manager -> Hjem

**Goal:** Replace the current Home-Manager user configuration with [hjem](https://github.com/feel-co/hjem).
**Scope:** Fidelity + simplify — keep current behavior, consolidate where Hjem's model encourages it.
**Approach:** Raw linked files only — no custom Hjem modules, no Hjem Rum.

> Hjem core = file linking (`hjem.users.<username>.files`) + `packages` + systemd user units.
> It ships NO per-program modules; everything else is written as linked files / generators.

---

## Architecture changes

| Where | Change |
|-------|--------|
| `flake.nix` | Add `hjem` input (`github:feel-co/hjem`, `inputs.nixpkgs.follows`). Remove `home-manager` input. |
| `configuration.nix` (`core` module) | Replace `home-manager.sharedModules`/`extraSpecialArgs` with `hjem.nixosModules.default` + `hjem.extraModules = []`. Drop `home-manager.*` flags (`useGlobalPkgs`, `backupFileExtension`). sops moved out to `system/nix/sops.nix` (see hard problem #2). |
| `system/nix/sops.nix` (**new**) | Owns all `sops.*` config **and** imports `inputs.sops-nix.nixosModules.sops` (self-contained); imported by `system/nix/default.nix`. Keeps `configuration.nix` uncluttered. |
| `system/nix/home/default.nix` | `home.users.dev` -> `hjem.users.dev` with `directory = "/home/dev"`, `imports = [...]`, `packages = [...]`, `clobberFiles = true`. Remove `home-manager.enable`, `home.stateVersion`. |
| `system/nix/user.nix` | Keep account creation; Hjem forwards `hjem.users.dev.packages` -> `users.users.dev.packages` automatically. |

Keep the modular file organization under `home/` (small `.nix` files), each contributing to
`hjem.users.dev.files` / `.packages` / `.systemd` / `.environment` — but with **no program modules**.

## Module inputs (how modules reach shared values)

- Values already present in the NixOS `config` are reached via the `config` input:
  `config.rv.editor` / `config.rv.nvim` (was `osConfig.rv.*`), `config.networking.hostName`
  (was `osConfig.networking.hostName`).
- Flake inputs that used to come through `home-manager.extraSpecialArgs`
  (`unsloth`, `zen-browser`, `noctalia`) are exposed to Hjem user modules by adding `inputs`
  to the NixOS module inputs, e.g. `_config.args = { inherit inputs; }`, so modules destructure
  `{ inputs, ... }` and reach `inputs.unsloth`, `inputs.zen-browser`, `inputs.noctalia`.
- Note: `pkgs`, `lib`, `self`, `osConfig` are also available as normal module args.

---

## Per-module mapping (fidelity + simplify)

| Current | Hjem equivalent |
|---------|-----------------|
| `dev/default.nix` packages | -> `hjem.users.dev.packages` (nvim via `osConfig.rv.*`, unsloth, etc.) |
| `dev/git.nix` | -> `~/.gitconfig` as `.text` (INI) |
| `dev/fish.nix` | -> `~/.config/fish/fish.conf` as `.source`/`.text` (keep `rv` alias) |
| `dev/ghostty.nix` | -> `~/.config/ghostty/config` as `.text` |
| `dev/lsd.nix` | -> `~/.config/lsd/config.yaml` via `.generator` (`pkgs.formats.yaml`) + a fish alias |
| `dev/bat.nix` | -> `MANPAGER` in `environment.sessionVariables` + bat package (no config file needed) |
| `dev/opencode/` | -> `~/.config/opencode/opencode.json` via **JSON generator** + `type = "copy"`, see notes below |
| `audio/beets.nix` | -> `~/.config/beets/config.yaml` via `.generator` |
| `audio/mpd.nix` | -> `~/.config/mpd.conf` linked file **+** `systemd.services.mpd` user unit |
| `niri/` | -> validated `~/.config/niri/config.kdl` as `.source` (keep the `niri validate` build-time check) |
| `obs.nix` | -> obs-studio + plugin packages only (config left to user) |
| `obsidian.nix` | -> obsidian package only |
| `noctalia.nix` | -> `~/.config/noctalia/config.toml` via `.generator` (TOML) **+** `systemd.services.noctalia` |
| `ssh.nix` | -> `~/.ssh/config` as `.text`; **secrets handling — see hard problems** |
| `zen-browser/` | -> **Firefox profile — see hard problems** |

---

## `opencode.json` specifics (per user notes)

- Use a **JSON generator** rather than copying the current `opencode.json` into the nix store.
  - i.e. `.generator = pkgs.formats.json {}.generate;` with a `value` attrset mirroring the current JSON.
- Use `type = "copy"` so the generated file is **copied** (not symlinked) to `~/.config/opencode/opencode.json`.

```nix
".config/opencode/opencode.json" = {
  type    = "copy";
  generator = pkgs.formats.json {}.generate;
  value   = {
    "$schema" = "https://opencode.ai/config.json";
    model     = "unsloth/ornith-1.5";
    providers = { /* ... */ };
  };
};
```

---

## Hard problems (decisions pending)

**1. Zen-browser Firefox profile.** Confirmed via `youwen5/zen-browser-flake` source that its
package (`zen-browser-unwrapped.nix`) only bakes in **policies** → `distribution/policies.json`
via `config.zen.policies`. It does NOT handle `user.js`, bookmarks, search, or extensions.
- In the current config these come from **nixpkgs's `mkFirefoxModule`** (rebranded as the project's
  zen-browser HM module in `system/nix/home/zen-browser/default.nix`), NOT from zen-browser-flake.
- Studied `nix-community/home-manager`'s `programs/firefox/mkFirefoxModule.nix`: it is a module
  factory that renders the whole profile into `home.file` — `profiles.ini`, `user.js`,
  `containers.json`, `handlers.json`, the `extensions/` dir, and (the hard/fragile parts)
  `bookmarks.json` (New Bookmarks Format, via `profiles/bookmarks.nix`) and
  `search.json.mozlz4` (Mozilla-LZ4, via `profiles/search.nix`). It also folds `policies` into the
  package override.
- **DECISION (confirmed): reuse `mkFirefoxModule` rather than hand-rolling renderers.** Inline the
  firefox module files (mkFirefoxModule.nix + `profiles/{bookmarks,search,handlers}.nix`) unmodified
  into the project, evaluate the rebranded module to harvest its concrete `home.file` attrset, then
  map each entry to `hjem.users.dev.files` (`text`→text, `source`→source, `force`→`clobber`).
  This reuses all rendering verbatim. Requires a minimal `home.*` option harness
  (`home.file`/`home.packages`/`home.stateVersion`/`home.homeDirectory`) so the module can be
  evaluated outside home-manager. (`search.json.mozlz4`, not `.mozill`.)
- **Approach (confirmed): full-module harvest.** Inline `mkFirefoxModule.nix` +
  `profiles/{bookmarks,search,handlers}.nix` unmodified into the project; evaluate the rebranded
  module (via a minimal `home.*` option harness: `home.file`/`home.packages`/`home.stateVersion`/
  `home.homeDirectory`) to harvest the complete concrete `home.file` attrset; map each entry to
  `hjem.users.dev.files` (`text`→text, `source`→source, `force`→`clobber`, dir `.source` recursive).
  Reuses all rendering verbatim (profiles.ini, user.js, containers, handlers, extensions, bookmarks
  NBF, search mozlz4, policies).

**2. SOPS-decrypted SSH keys — DECISION: use sops-nix default NixOS module.**
- Move `sops.*` out of the home namespace (`ssh.nix`) into a new `system/nix/sops.nix`, imported by
  `system/nix/default.nix` — kept **out** of `configuration.nix` per user request. (`discover.nix`
  already uses the NixOS module and is unchanged.)
- `system/nix/sops.nix` also imports `inputs.sops-nix.nixosModules.sops` so it is self-contained.
- Config:
  ```nix
  sops.defaultSopsFile = ./secrets/ssh.dev.yaml;
  sops.age.keyFile = "/persistent/home/dev/.config/sops/age/keys.txt"; # placed by bootstrap; unchanged
  sops.age.generateKey = false;
  sops.secrets."host/${config.networking.hostName}/master" = { owner = "dev"; path = "/home/dev/.ssh/id_ed25519"; };
  sops.secrets."host/${config.networking.hostName}/github"    = { owner = "dev"; path = "/home/dev/.ssh/github"; };
  ```
- `path` creates a symlink `<target> -> /run/secrets/<name>` at NixOS activation.
- **OPEN (now confirmed): `.ssh` directory + permissions.** Hjem creates `~/.ssh` as a
  `type = "directory"` (0700) entry and links `~/.ssh/config` (text); sops-nix `path` symlinks
  place the two private keys. Verify activation ordering (Hjem tmpfiles vs sops activation) and
  add systemd `After`/`Requires` on the sops service only if the symlink creation races.

---

## Stays in system config (unchanged)

`users.users.dev` account, `mutableUsers`, `greetd` auto-login,
`programs.fish/niri/dconf/wireshark/steam`, `environment.etc.nixos.source`,
`environment.systemPackages` (xwayland-satellite), hardware reports, installer flow.
