# devcontainer-features

A collection of devcontainer features that keep tool credentials and state in Docker volumes, so tools stay authenticated across rebuilds without mounting anything from the host.

## Features

| Feature | Feature URL | Requires | Kept per container |
|---------|-------------|----------|--------------------|
| [`claude`](#claude) | `ghcr.io/sarisia/devcontainer-features/claude:3` | — | `~/.claude` (incl. login) |
| [`opencode`](#opencode) | `ghcr.io/sarisia/devcontainer-features/opencode:4` | npm | `~/.local/share/opencode`, `~/.agents` |
| [`gh`](#gh) | `ghcr.io/sarisia/devcontainer-features/gh:3` | — | `~/.config/gh` |
| [`glab`](#glab) | `ghcr.io/sarisia/devcontainer-features/glab:3` | — | `~/.config/glab-cli` |
| [`codex`](#codex) | `ghcr.io/sarisia/devcontainer-features/codex:4` | npm | `~/.codex` (incl. login), `~/.agents` |
| [`fish`](#fish) | `ghcr.io/sarisia/devcontainer-features/fish:2` | — | fish history |

> **npm**: can be installed natively on the host or via the [`ghcr.io/devcontainers/features/node:2`](https://github.com/devcontainers/features/tree/main/src/node) devcontainer feature.

> **Renamed:** `claude-code` → `claude` and `fish-shell-history` → `fish`. The old feature URLs are still
> published as aliases (`legacyIds`) and resolve to the current features.

## How state is kept

Nothing is mounted from the host. Each feature mounts Docker volumes under `/mnt` and points the tool at them, through its config-dir variable where it has one and a symlink at the usual home path (e.g. `~/.codex -> /mnt/codex-home`) for everything else.

- **Volumes survive rebuilds.** Every volume is named `<name>-${devcontainerId}`, so it belongs to one dev container and comes back when that container is rebuilt.
- **Logins are per container, never shared.** Log in once per project; a token leaked from one container works nowhere else, and each project can use its own scoped token (e.g. a fine-grained GitHub PAT). `devcontainerId` changes when the workspace path changes, which means a fresh login.
- **Configure with dotfiles.** The home paths are symlinks into the volumes, so a dotfiles installer can drop `settings.json`, `config.toml`, skills, … there. A path the image already has is left alone.
- **Reset** by deleting the volume: `docker volume ls` lists them.
- **Overlapping volumes are fine.** `codex`/`opencode` declare the same `agents-${devcontainerId}` volume; the devcontainer CLI mounts it once.
- **UID remapping is handled.** On Linux hosts `updateRemoteUserUID` changes the remote user's UID after the features are installed and only re-owns `$HOME`, so the volumes would keep the old owner. Each feature's `postCreateCommand` takes ownership of its volumes with `sudo chown` when they don't belong to the remote user. It needs passwordless `sudo`, which the `mcr.microsoft.com/devcontainers` images have.

### `claude`

Installs [Claude Code](https://claude.ai/code) CLI via the official apt repository. The `channel` option selects the apt release channel (`latest` or `stable`, default: `latest`).

Nothing is mounted from the host. State lives in Docker volumes that survive rebuilds:

| Volume | Path | Holds |
|--------|------|-------|
| `claude-config-${devcontainerId}` | `/mnt/claude-config` | Settings, sessions, `.claude.json`, `.credentials.json` (`CLAUDE_CONFIG_DIR`) |

- **`~/.claude` is a symlink to `/mnt/claude-config`**, so a dotfiles installer can put `settings.json`, `CLAUDE.md`, `skills` there. It is left alone if the image already has `~/.claude`.
- **Reset a container's state** by deleting its `claude-config-<id>` volume (`docker volume ls | grep claude`).

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/claude:3": {
        "channel": "stable"
    }
}
```

---

### `opencode`

Installs [OpenCode](https://opencode.ai) CLI via npm — see [How state is kept](#how-state-is-kept).

| Volume | Path | Holds |
|--------|------|-------|
| `opencode-data-${devcontainerId}` | `/mnt/opencode-data` (`~/.local/share/opencode`) | Sessions and login, per container |
| `agents-${devcontainerId}` | `/mnt/agents` (`~/.agents`) | Shared skills dir, per container |

OpenCode keeps its login in the same database as its sessions, so the login can't be shared without sharing sessions: log in once per container. To use Claude Code's skills and `CLAUDE.md`, add the `claude` feature, which provides `~/.claude`.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/opencode:4": {}
}
```

---

### `gh`

Installs the latest [GitHub CLI](https://cli.github.com) and keeps `~/.config/gh` in the `gh-config-${devcontainerId}` volume at `/mnt/gh-config` (`GH_CONFIG_DIR`): `gh auth login` once per container — see [How state is kept](#how-state-is-kept). The `extensions` option is a comma-separated list of extensions installed with `gh extension install` (default: `github/gh-stack`); set it to an empty string to install none.

Also installs the official [`cli/cli` `gh` skill](https://github.com/cli/cli/blob/trunk/skills/gh/SKILL.md), pinned to the installed `gh` version, as a symlink into Claude Code's managed skills dir (`/etc/claude-code/.claude/skills`) and Codex's admin skills dir (`/etc/codex/skills`). Both are system-wide locations outside any volume, so they're populated for every agent without touching `~/.claude/skills` or `~/.agents/skills`.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/gh:3": {
        "extensions": "github/gh-stack,github/gh-skyline"
    }
}
```

---

### `glab`

Installs the latest [GitLab CLI](https://gitlab.com/gitlab-org/cli) and keeps `~/.config/glab-cli` in the `glab-config-${devcontainerId}` volume at `/mnt/glab-config` (`GLAB_CONFIG_DIR`): `glab auth login` once per container — see [How state is kept](#how-state-is-kept).

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/glab:3": {}
}
```

---

### `codex`

Installs [Codex CLI](https://developers.openai.com/codex/cli) via npm — see [How state is kept](#how-state-is-kept). Requires Node.js — add the [node feature](https://github.com/devcontainers/features/tree/main/src/node) to your devcontainer.

| Volume | Path | Holds |
|--------|------|-------|
| `codex-home-${devcontainerId}` | `/mnt/codex-home` (`CODEX_HOME`, `~/.codex`) | Config, sessions and `auth.json`, per container |
| `agents-${devcontainerId}` | `/mnt/agents` (`~/.agents`) | Shared skills dir, per container |

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/codex:4": {}
}
```

---

### `fish`

Installs [fish shell](https://fishshell.com) v4 from the static build on [GitHub releases](https://github.com/fish-shell/fish-shell/releases) to `/usr/local/bin/fish`, and keeps shell history in the `fish-shell-history-${devcontainerId}` volume at `/mnt/fish-shell-history`, per container — see [How state is kept](#how-state-is-kept). Only `~/.local/share/fish/fish_history` is a symlink into the volume. It is left alone if the image already has a real history file there. The `version` option pins a release tag such as `4.9.3` (default: `latest`).

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/fish:2": {}
}
```

If history isn't persisting, run this inside the container to see fish's own (normally silent) history save errors:

```sh
fish --debug=history,history_file -c 'echo x; history save'
```
