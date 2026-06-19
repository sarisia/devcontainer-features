# devcontainer-features

A collection of devcontainer features that mount host credentials and configs into the container so tools stay authenticated across rebuilds.

## Features

| Feature | Feature URL | Requires | Host Mounts |
|---------|-------------|----------|-------------|
| [`claude`](#claude) | `ghcr.io/sarisia/devcontainer-features/claude:1` | — | `~/.claude`, `~/.claude.json` |
| [`opencode`](#opencode) | `ghcr.io/sarisia/devcontainer-features/opencode:1` | npm | `~/.claude`, `~/.local/share/opencode` |
| [`gh`](#gh) | `ghcr.io/sarisia/devcontainer-features/gh:1` | — | `~/.config/gh` |
| [`glab`](#glab) | `ghcr.io/sarisia/devcontainer-features/glab:1` | — | `~/.config/glab-cli` |
| [`codex`](#codex) | `ghcr.io/sarisia/devcontainer-features/codex:1` | npm | `~/.codex` |
| [`fish`](#fish) | `ghcr.io/sarisia/devcontainer-features/fish:1` | — | — |

> **npm**: can be installed natively on the host or via the [`ghcr.io/devcontainers/features/node:2`](https://github.com/devcontainers/features/tree/main/src/node) devcontainer feature.

### `claude`

Installs [Claude Code](https://claude.ai/code) CLI via the official apt repository and mounts `~/.claude` / `~/.claude.json` from the host so settings and sessions persist. The `channel` option selects the apt release channel (`latest` or `stable`, default: `latest`).

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

### `codex`

Installs [Codex CLI](https://developers.openai.com/codex/cli) via npm and mounts `~/.codex` from the host so auth and sessions persist. Requires Node.js — add the [node feature](https://github.com/devcontainers/features/tree/main/src/node) to your devcontainer.

```json
"features": {
    "ghcr.io/sarisia/devcontainer-features/codex:1": {}
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
