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

- Values already present in the NixOS config are reached via the **`osConfig`** input inside
  Hjem user modules: `osConfig.rv.editor` / `osConfig.rv.nvim`, `osConfig.networking.hostName`.
  Verified against Hjem source (`modules/nixos/base.nix`): each `hjem.users.<username>` is
  evaluated as its own module system where `config` is the *user*-scoped config and the NixOS
  config arrives as the special arg `osConfig`. Same `osConfig` convention the current HM
  modules already use — no rename needed.
- Flake inputs that used to come through `home-manager.extraSpecialArgs`
  (`unsloth`, `zen-browser`, `noctalia`) are exposed by passing `inputs` through each host's
  `nixosSystem` call: `specialArgs = {inherit inputs;};` (already wired in all three host
  files). Modules destructure `{ inputs, ... }` and reach `inputs.unsloth`,
  `inputs.zen-browser`, `inputs.noctalia`. (`hjem.specialArgs` is an alternative Hjem-level
  knob; not needed.)
- Note: `pkgs`, `lib`, `osConfig`, plus Hjem's own `hjem-lib`/`utils` args, are also available
  in user modules.

## Hjem API notes (verified against docs + source)

- File entries accept `type = symlink|copy|delete|directory|modify` (default `symlink`).
  `source`/`text` are only allowed — and required — for `symlink`/`copy`;
  `permissions`/`uid`/`gid` are only allowed for `copy`/`directory`/`delete`/`modify`, so
  setting them on a `symlink` entry throws. A `type = "directory"` entry needs no `source`.
- `generator` auto-detects its output: a derivation becomes `source` (store file), a string
  becomes `text`. So `pkgs.formats.{json,yaml} {}.generate` -> store file;
  `lib.generators.toGitINI` -> inline text.
- XDG file namespaces exist as an alternative to dotted paths:
  `xdg.config.files."opencode/opencode.json"` ~= `files.".config/opencode/opencode.json"`.
  Both merge into one manifest per user; noctalia's Hjem module emits `xdg.config.files`, so
  mixing both styles in one user config is fine.
- User systemd units (`systemd.services` & friends, full NixOS unit options) are linked into
  `~/.config/systemd/user/` and registered in system `systemd.units`; `hjem-reload@<user>`
  reloads changed user units after file activation when the user manager is running.
- Each user config is a standard NixOS module: `imports` and `assertions` work, which is what
  makes per-user `imports = [inputs.noctalia.hjemModules.default]` valid.

---

## Per-module mapping (fidelity + simplify)

| Current | Hjem equivalent |
|---------|-----------------|
| `dev/default.nix` packages | -> `hjem.users.dev.packages` (nvim via `osConfig.rv.*`, unsloth, etc.) |
| `dev/git.nix` | -> `xdg.config.files."git/config"` (`~/.config/git/config` — HM's actual XDG location, not `~/.gitconfig`) via `.generator` (`lib.generators.toGitINI`, byte-identical to HM) + git in `packages` |
| `dev/fish.nix` | -> `xdg.config.files."fish/config.fish"` (the file fish actually loads — earlier draft said `fish.conf`, which fish ignores; HM wrote its generated config to `config.fish`): greeting off + `e`/`rv` aliases under an interactive guard, rendered with HM's `escapeShellArg`; `rv` uses `osConfig.rv.editor` (was `nixosConfig.rv.editor`). No fish package here — provided by system-level `programs.fish`; lsd aliases live in `conf.d/lsd.fish` |
| `dev/ghostty.nix` | -> `xdg.config.files."ghostty/config"` via keyValue `.generator` (`listsAsDuplicateKeys = true`, `" = "` — byte-identical to HM) + ghostty package **+** the app-service unit & `overrides.conf` drop-in linked from the package (HM's default-on `programs.ghostty.systemd` on Linux; verified the unit exists in pkgs.ghostty 1.3.1) |
| `dev/lsd.nix` | -> lsd package; `xdg.config.files."lsd/colors.yaml"` (catppuccin-latte) **and** `"lsd/config.yaml"` (`color.theme: custom`, which HM auto-adds whenever colors is set) via `pkgs.formats.yaml` `.generator`s; fish aliases (`ls/ll/la/lt/lla/llt`) as `fish/conf.d/lsd.fish` rendered with HM's exact `alias <k> <escapeShellArg v>` form |
| `dev/bat.nix` | -> bat package; `xdg.config.files."bat/config"` via HM's `toConfigFile` renderer (`--key=value` lines) fed by ghostty's `map-syntax`; `"bat/syntaxes/ghostty.sublime-syntax"` linked from `pkgs.ghostty` (HM's default-on `installBatSyntax`, file = `share/bat/syntaxes/ghostty.sublime-syntax` — verified present); `MANPAGER` set in the fish config text (`set -gx MANPAGER ...`) — see environment-variables note below. **OPEN:** HM also ran `bat cache --build` via a `home.activation` hook after linkGeneration; decide the Hjem equivalent (skip vs. user oneshot unit) |
| `dev/opencode/` | -> `~/.config/opencode/opencode.json` via **JSON generator** + `type = "copy"`, see notes below |
| `audio/beets.nix` | -> `~/.config/beets/config.yaml` via `.generator` |
| `audio/mpd.nix` | -> `~/.config/mpd.conf` linked file **+** `systemd.services.mpd` user unit |
| `niri/` | -> validated `~/.config/niri/config.kdl` as `.source` (keep the `niri validate` build-time check) |
| `obs.nix` | -> obs-studio + plugin packages only (config left to user) |
| `obsidian.nix` | -> obsidian package only |
| `noctalia.nix` | import `noctalia.hjemModules.default`; keep `programs.noctalia` options (enable, systemd.enable, settings). Emits `packages`, `systemd.services.noctalia`, `xdg.config.files` (validated `config.toml`). No manual generator/unit. |
| `ssh.nix` | -> `~/.ssh/config` as `.text`; **secrets handling — see hard problems** |
| `zen-browser/` | -> **Firefox profile — see hard problems** |

---

## Upstream Hjem modules (prefer over hand-rolling)

Some upstream projects ship ready-made Hjem modules. These should be preferred over
hand-rolling linked-file / systemd logic.

### noctalia

`noctalia` exposes three module variants in its flake outputs: `homeModules.default`
(home-manager), `hjemModules.default` (Hjem), and `nixosModules.default` (NixOS).

```nix
# system/nix/home/noctalia.nix (after)
{ inputs, osConfig, pkgs, ... }: {
  imports = [inputs.noctalia.hjemModules.default];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = { ... };   # unchanged from the home-manager version
  };
}
```

- Declares the **same** `programs.noctalia` options as the home-manager module
  (`enable`, `systemd.enable`, `systemd.target`, `package`, `validateConfig`,
  `settings`, `customPalettes`), so the module body is otherwise unchanged.
- Emits `packages`, `systemd.services.noctalia` (`wantedBy = [systemd.target]`,
  `enableDefaultPath = false` so it does not clobber the user manager PATH), and
  `xdg.config.files` — `noctalia/config.toml` via `toml.generate` plus optional
  `noctalia/palettes/<name>.json`.
- `noctalia.hjemModules.default` sets
  `programs.noctalia.package = lib.mkDefault self.packages.<system>.default`, so the
  package is provided and `validateConfig` (default `true`) validates `config.toml` at
  build time. No manual TOML generator or systemd unit is needed.
- `noctalia.settings.wallpaper.default.path = ../../../wallpaper.png` is a Nix path;
  `toml.generate` stringifies it (matches prior behavior).

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

## Environment variables (verified caveat)

Hjem's `environment.sessionVariables` does NOT inject anything into the user session by
itself; it only renders a POSIX (`export ...`) script at `environment.loadEnv`, which must be
sourced manually. Our session shell is fish, which cannot source bash syntax, so variables
set only via `sessionVariables` would silently have no effect.

**PENDING DECISION (recommended):** set user-facing variables (e.g. `MANPAGER` for bat)
directly in the fish config text as `set -gx NAME value;`; keep `environment.sessionVariables`
empty unless a POSIX-sourcing consumer appears.

---

## Hard problems (decisions pending)

**1. Zen-browser Firefox profile.** Confirmed via `youwen5/zen-browser-flake` source that its
package (`zen-browser-unwrapped.nix`) only bakes in **policies** → `distribution/policies.json`
via `config.zen.policies`. It does NOT handle `user.js`, bookmarks, search, or extensions.
- In the current config these come from **home-manager's `mkFirefoxModule`** (rebranded as the
  project's zen-browser HM module in `system/nix/home/zen-browser/default.nix`), NOT from
  zen-browser-flake, and NOT from nixpkgs (nixpkgs no longer ships this module). Source of record:
  https://raw.githubusercontent.com/nix-community/home-manager/master/modules/programs/firefox/mkFirefoxModule.nix
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
- **CONFIRMED (with one open verification): `.ssh` directory + permissions.** Hjem creates
  `~/.ssh` as a `type = "directory"` (0700) entry and links `~/.ssh/config` (text); sops-nix
  `path` symlinks place the two private keys. Activation ordering is now verified: with the
  default CLI linker, sops-nix tmpfiles place the key symlinks at *sysinit*, while Hjem's
  `hjem-activate@dev` service runs later at *multi-user* as user `dev` — no race there. The
  remaining risk is **clobber semantics**, not ordering: on an impermanent boot `/home/dev`
  starts empty, sops tmpfiles create `~/.ssh` + the key symlinks first, and if Hjem's CLI
  linker *recreates* an already-existing target for a `type = "directory"` entry it would wipe
  those symlinks within the same boot. ACTION: verify how the CLI linker treats an existing
  directory target (test in qemu before desktop); fallbacks are letting sops/tmpfiles own the
  directory (drop Hjem's `.ssh` entry, keep only `config`) or using non-destructive semantics
  for it.

---

## Stays in system config (unchanged)

`users.users.dev` account, `mutableUsers`, `greetd` auto-login,
`programs.fish/niri/dconf/wireshark/steam`, `environment.etc.nixos.source`,
`environment.systemPackages` (xwayland-satellite), hardware reports, installer flow.

## Progress (as of 2026-10-28)

Done (commits `260a0b4`, `f889016`):
- [x] `flake.nix`: `home-manager` input -> `hjem`; `configuration.nix` imports
      `hjem.nixosModules.default`, HM flags/args dropped
- [x] `system/nix/sops.nix` created (self-contained, owns dev SSH-key secrets) and imported
      by `system/nix/default.nix`
- [x] All three hosts pass `specialArgs = {inherit inputs;}` to their `nixosSystem` calls
- [x] `system/nix/home/default.nix`: `home-manager.users.dev` -> `hjem.users.dev`
      (`directory`, `clobberFiles`, `imports`, `packages`)

Remaining:
- [ ] Convert every module under `system/nix/home/` from HM style to Hjem linked files /
      generators / units (the tree does not build until this is done)
- [ ] zen-browser Firefox profile harvest (hard problem #1) — biggest remaining item
- [ ] Verify `.ssh` directory clobber behavior in qemu (hard problem #2 action)
- [ ] Confirm environment-variable approach (fish `set -gx` vs `sessionVariables`)
