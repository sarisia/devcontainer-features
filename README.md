# devcontainer-features

A collection of devcontainer features that mount host credentials and configs into the container so tools stay authenticated across rebuilds.

## Features

### `claude`

Installs [Claude Code](https://claude.ai/code) CLI and mounts `~/.claude` / `~/.claude.json` from the host so settings and sessions persist.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/claude:1": {}
}
```

---

### `opencode`

Installs [OpenCode](https://opencode.ai) CLI and mounts `~/.claude` / `~/.local/share/opencode` from the host so settings and sessions persist.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/opencode:1": {}
}
```

---

### `gh`

Installs the latest [GitHub CLI](https://cli.github.com) and mounts `~/.config/gh` from the host so auth tokens persist.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/gh:1": {}
}
```

---

### `glab`

Installs the latest [GitLab CLI](https://gitlab.com/gitlab-org/cli) and mounts `~/.config/glab-cli` from the host so auth tokens persist.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/glab:1": {}
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
