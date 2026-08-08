# devcontainer-features

A collection of devcontainer features that mount host credentials and configs into the container so tools stay authenticated across rebuilds.

## Features

| Feature | Feature URL | Requires | Host Mounts |
|---------|-------------|----------|-------------|
| [`claude`](#claude) | `ghcr.io/sarisia/devcontainer-features/claude:2` | — | `~/.claude`, `~/.claude.json` |
| [`opencode`](#opencode) | `ghcr.io/sarisia/devcontainer-features/opencode:3` | npm | `~/.claude`, `~/.local/share/opencode`, `~/.agents` |
| [`gh`](#gh) | `ghcr.io/sarisia/devcontainer-features/gh:2` | — | `~/.config/gh` |
| [`glab`](#glab) | `ghcr.io/sarisia/devcontainer-features/glab:2` | — | `~/.config/glab-cli` |
| [`codex`](#codex) | `ghcr.io/sarisia/devcontainer-features/codex:3` | npm | `~/.codex`, `~/.agents` |
| [`fish`](#fish) | `ghcr.io/sarisia/devcontainer-features/fish:1` | — | — |

> **npm**: can be installed natively on the host or via the [`ghcr.io/devcontainers/features/node:2`](https://github.com/devcontainers/features/tree/main/src/node) devcontainer feature.

## How mounts are linked

These features mount host directories into the container and symlink them into place at container start — one link per top-level entry (`~/.claude/projects`, `~/.config/gh/hosts.yml`, …), not a symlink over the whole directory.

- **Existing container entries win.** Anything already at, say, `~/.claude/settings.json` is left alone, so a dotfiles installer can own config files.
- **`exclude`** is a comma-separated list of entry names to keep container-local (e.g. `settings.json,skills`).
- **New state is adopted.** A directory a tool creates in the container is moved onto the host on the next container start, then symlinked back.
- **Overlapping mounts are fine.** `claude`/`opencode` share `~/.claude`, `codex`/`opencode` share `~/.agents`; linking is idempotent. Set the same `exclude` on both, or one will link what the other skips.

On a Linux host with a UID-mismatched remote user, adopted directories are owned by the container UID.

### `claude`

Installs [Claude Code](https://claude.ai/code) CLI via the official apt repository and mounts `~/.claude` / `~/.claude.json` from the host — see [How mounts are linked](#how-mounts-are-linked). The `channel` option selects the apt release channel (`latest` or `stable`, default: `latest`).

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/claude:2": {
        "channel": "stable",
        "exclude": "settings.json,CLAUDE.md,skills"
    }
}
```

---

### `opencode`

Installs [OpenCode](https://opencode.ai) CLI and mounts `~/.claude` / `~/.local/share/opencode` / `~/.agents` from the host — see [How mounts are linked](#how-mounts-are-linked).

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/opencode:3": {
        "exclude": "settings.json,skills"
    }
}
```

---

### `gh`

Installs the latest [GitHub CLI](https://cli.github.com) and mounts `~/.config/gh` from the host — see [How mounts are linked](#how-mounts-are-linked). The `extensions` option is a comma-separated list of extensions installed with `gh extension install` (default: `github/gh-stack`); set it to an empty string to install none.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/gh:2": {
        "extensions": "github/gh-stack,github/gh-skyline",
        "exclude": "config.yml"
    }
}
```

---

### `glab`

Installs the latest [GitLab CLI](https://gitlab.com/gitlab-org/cli) and mounts `~/.config/glab-cli` from the host — see [How mounts are linked](#how-mounts-are-linked).

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/glab:2": {
        "exclude": "config.yml"
    }
}
```

---

### `codex`

Installs [Codex CLI](https://developers.openai.com/codex/cli) via npm and mounts `~/.codex` / `~/.agents` from the host — see [How mounts are linked](#how-mounts-are-linked). Requires Node.js — add the [node feature](https://github.com/devcontainers/features/tree/main/src/node) to your devcontainer.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/codex:3": {
        "exclude": "config.toml,skills"
    }
}
```

---

### `fish`

Installs [fish shell](https://fishshell.com) v4 and persists shell history in a named Docker volume across rebuilds.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/fish:1": {}
}
```

## Development

`claude`, `opencode`, `codex`, `gh` and `glab` share the linking library at `shared/link-mounts.sh`. Run `make` after editing it to refresh the per-feature copies under `.devcontainer/features/*/link-mounts.sh` — those are gitignored build output, regenerated in CI before publish. Each feature's committed `links.sh` is the `postStartCommand` entry point; it sources the library and calls `link` once per mount in its `devcontainer-feature.json`.
