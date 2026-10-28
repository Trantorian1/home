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
  (`unsloth`, `zen-browser`, `noctalia`) reach Hjem user modules via **`hjem.specialArgs`** —
  set once in `system/nix/home/default.nix` as `hjem.specialArgs = {inherit inputs;};`.
  Modules destructure `{ inputs, ... }` and reach `inputs.unsloth`,
  `inputs.zen-browser`, `inputs.noctalia`.
  **CORRECTION (verified):** NixOS-level specialArgs (the hosts'
  `specialArgs = {inherit inputs;}` on their `nixosSystem` calls) do NOT flow into Hjem's user
  submodule — `modules/nixos/base.nix` builds the submodule with
  `specialArgs = cfg.specialArgs // { heim-lib osConfig pkgs utils osOptions }`, and nixpkgs'
  `submoduleWith` does not merge in the parent's specialArgs. An earlier draft of this plan
  claimed the host wiring was sufficient; it is not (a module destructuring a bare `noctalia`
  or `unsloth` arg fails with "argument not externally provided"). The hosts' NixOS-level
  `specialArgs = {inherit inputs;}` stays — top-level NixOS modules still need it.
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
- User systemd units (`systemd.services` & friends) are Hjem's own option types (NOT raw
  NixOS unit style): `description`, `after`/`before`/`requires`/..., `wantedBy`, `environment`,
  `path`, `enableDefaultPath` (default `true` — appends a minimal PATH of coreutils/findutils/
  gnugrep/gnused/systemd bins), and raw-section `serviceConfig`/`unitConfig`. Hjem renders each
  unit with nixpkgs' `utils.systemdUtils.lib.makeUnit` and links it to
  `~/.config/systemd/user/` plus `.wants/` symlinks for `wantedBy`; `hjem-reload@<user>` reloads
  changed user units after file activation when the user manager is running.
- **Verified:** Hjem's modules destructure a `utils` arg that Hjem itself never defines — it
  comes from nixpkgs: `nixos/modules/misc/extra-arguments.nix` injects
  `_module.args.utils = import nixos/lib/utils.nix {...}` into every NixOS module. So Hjem user
  systemd options only work inside a real NixOS system evaluation (they do; harness must force
  them, e.g. by reading `hjem.users.<u>.systemd.units`).
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
| `dev/bat.nix` | -> bat package; `xdg.config.files."bat/config"` via HM's `toConfigFile` renderer (`--key=value` lines, byte-identical — verified by reconstructing the exact writeTextFile drv) fed by ghostty's `map-syntax`; `"bat/syntaxes/ghostty.sublime-syntax"` linked from `pkgs.ghostty` (HM's default-on `installBatSyntax`, file = `share/bat/syntaxes/ghostty.sublime-syntax` — verified present); `MANPAGER` in `fish/conf.d/bat.fish` as `set -gx MANPAGER "bat -l man -p"` (user-confirmed option 1; Hjem's `sessionVariables` cannot reach a fish session). **DECISION:** HM's `home.activation.batCache` hook (`bat cache --build`) is skipped for now — the cache rebuilds lazily on first use after each impermanent boot; revisit only if post-reboot bat startup feels slow |
| `dev/opencode/` | -> `xdg.config.files."opencode/opencode.json"` with `type = "copy"` + JSON `.generator` (see notes below); flattened to `dev/opencode.nix` and moved into `dev/default.nix` imports (was imported from `user.nix` at NixOS level because the old module used `system.userActivationScripts`) |
| `audio/beets.nix` | -> beets package + `xdg.config.files."beets/config.yaml"` via `pkgs.formats.yaml` `.generator` (HM's exact format, byte-identical); home paths use Hjem's `config.directory` (equivalent of HM's `config.home.homeDirectory`). HM's optional mpd integration (mpdstats/mpdupdate) is not used by this project — nothing to carry over |
| `audio/mpd.nix` | -> mpd package + `systemd.services.mpd` user unit (Hjem's own service type, rendered via nixpkgs' systemdUtils). **CORRECTION:** HM never placed an mpd.conf in the home — it passed the generated config from the store as a CLI arg (`mpd --no-daemon /nix/store/...-mpd.conf`); reproduced exactly (earlier draft said `~/.config/mpd.conf` linked file). Config text is byte-identical to HM's generatedConfig (verified against a verbatim copy of HM's expression, incl. the trailing blank line from its final fragment). MPD_HOST/MPD_PORT session vars (HM default on) -> `fish/conf.d/mpd.fish`. Unit PATH: Hjem/nixpkgs default path (coreutils/findutils/gnugrep/gnused/systemd via `enableDefaultPath`) instead of HM's profile-bin-only PATH — functionally irrelevant here (absolute paths in ExecStart/ExecStartPre, pipewire output is internal) |
| `niri/` | -> validated `~/.config/niri/config.kdl` as `.source` (keep the `niri validate` build-time check) |
| `obs.nix` | -> obs-studio + plugin packages only (config left to user) |
| `obsidian.nix` | -> obsidian package only |
| `noctalia.nix` | import `inputs.noctalia.hjemModules.default` (module now destructures `{ inputs, ... }`); keep `programs.noctalia` options unchanged (enable, systemd.enable, settings). Verified at pinned rev 6423cc2: the Hjem variant declares the same options and emits `packages`, `systemd.services.noctalia`, `xdg.config.files` (validated `config.toml`). **NOTE:** the HM variant referenced `config.wayland.systemd.target`, which does not exist in the locked nixpkgs 26.11 (dangling reference — the pre-refactor tree could not evaluate); the Hjem module uses its own `systemd.target` option, default `graphical-session.target`, matching nixpkgs' native `programs.noctalia` module |
| `ssh.nix` | -> `files.".ssh"` (`type = "directory"`, 0700) + `files.".ssh/config".text`. Config text is byte-identical to the pinned HM rendering (verified by evaluating old module rev 6750249: github.com block first, `*` last; directives sorted within blocks). Note: HM's `settings` path passes raw names through verbatim, so the old github.com block's camelCase names (`user`, `identityFile`, `identitiesOnly`) were rendered literally — OpenSSH directive names are case-insensitive, kept as-is for byte fidelity. The `sops.*` block is dropped (owned by `system/nix/sops.nix`). No package carried (HM `programs.ssh.package` defaulted to null). |
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

Verified (item done): `pkgs.formats.json` on the pinned nixpkgs renders pretty-printed
(2-space indent) with **sorted keys**, so on-disk bytes differ from the old file only in key
order — deep-compared the rendering against the original JSON: semantically identical. The
default Hjem linker is the CLI linker (`hjem.linker = cli.package`), which honors `type = "copy"`
(the systemd-tmpfiles fallback mode would symlink everything, so copy semantics depend on the
default linker). With `clobberFiles = true` the file is refreshed on every activation, matching
the old `cp -r` script.

## Environment variables (verified caveat)

Hjem's `environment.sessionVariables` does NOT inject anything into the user session by
itself; it only renders a POSIX (`export ...`) script at `environment.loadEnv`, which must be
sourced manually. Our session shell is fish, which cannot source bash syntax, so variables
set only via `sessionVariables` would silently have no effect.

**DECISION (confirmed 2026-10-28):** set user-facing variables (e.g. `MANPAGER` for bat)
directly in the fish config as `set -gx NAME value;` in a dedicated `fish/conf.d/*.fish` file;
keep `environment.sessionVariables` empty unless a POSIX-sourcing consumer appears.

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
- **RESOLVED: `.ssh` directory + permissions.** Hjem creates `~/.ssh` as a
  `type = "directory"` (0700) entry and links `~/.ssh/config` (text); sops-nix `path` symlinks
  place the two private keys. Activation ordering verified: with the default CLI linker,
  sops-nix tmpfiles place the key symlinks at *sysinit*, while Hjem's `hjem-activate@dev`
  service runs later at *multi-user* as user `dev` — no race there. The clobber question is
  now **verified against the pinned Hjem CLI** (rev d219ef55, built and run directly with a
  manifest in the exact shape `modules/nixos/base.nix` generates):
  - fresh home: `.ssh` created `0700`, `config` symlinked into it;
  - pre-existing `.ssh` containing key files (the impermanent-boot/sops scenario): contents
    preserved, no wipe, `config` linked in alongside — the linker does NOT recreate an
    existing directory target;
  - pre-existing `.ssh` with loose `0755` perms: re-chmodded to `0700`;
  - re-run with state present (incremental mode): no-op, everything stable.
  No qemu test needed; the fallbacks above are not required.

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
- [x] `.ssh` directory clobber behavior verified against the pinned Hjem CLI directly
      (contents preserved, perms enforced — see hard problem #2; qemu test no longer needed)
- [x] Environment-variable approach confirmed: fish `set -gx` in conf.d files (see above)

Converted so far (per-item harness-validated): `dev/git.nix`, `dev/ghostty.nix`,
`dev/lsd.nix`, `dev/fish.nix`, `dev/bat.nix`, `dev/opencode.nix`,
`audio/beets.nix`, `audio/mpd.nix`, `noctalia.nix`, `ssh.nix`. Remaining:
`zen-browser/`, and `home.packages` -> `packages` (the last one also fixes
`dev/default.nix`'s bare `unsloth` arg — see the specialArgs correction above).
