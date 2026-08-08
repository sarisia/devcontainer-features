# Sourced by the feature's links.sh, not executed directly.

DIR="$(dirname "$0")"
EXCLUDE="$(cat "${EXCLUDE_FILE:-$DIR/exclude}" 2>/dev/null || true)"

log() { echo "link-mounts: $*"; }

# Symlink $1 (a mount entry) to $2 (its target counterpart), unless the user
# excluded it by name, something this feature does not own already sits at the
# destination, or $1 is itself a symlink (host-side wiring, never state -- see
# below).
link_entry() {
    src=$1
    dst=$2
    name=${src##*/}

    [ -L "$src" ] && return 0                          # host wiring, never state
    [ -e "$src" ] || return 0                          # unmatched glob / absent mount
    case ",$EXCLUDE," in *",$name,"*) return 0 ;; esac

    [ -L "$dst" ] && return 0                          # already linked (ours, or the dotfiles install's): leave as is
    [ -e "$dst" ] && return 0                          # container-local real file/dir wins

    ln -sfn "$src" "$dst"
    log "linked $dst -> $src"
}

# The link loop below only sees what the mount already has, and link_entry
# deliberately never overwrites a real dir -- so anything a tool created
# container-locally while the host lacked it would stay local forever. Move it
# to the host and link back.
adopt_entry() {
    dst=$1
    mount=$2
    name=${dst##*/}

    [ -L "$dst" ] && return 0                          # ours, or the dotfiles install's
    [ -d "$dst" ] || return 0                          # dirs only; files are too risky
    case ",$EXCLUDE," in *",$name,"*) return 0 ;; esac
    [ -e "$mount/$name" ] && return 0                  # something already at the destination

    mv "$dst" "$mount/$name" || return 0               # cross-device copy; leave as-is on failure
    ln -sfn "$mount/$name" "$dst"
    log "adopted $dst -> $mount/$name"
}

link_dir() {
    mount=$1
    target=$2

    [ -d "$mount" ] || return 0

    # A v1-era layout leaves $target a symlink to the mount (host wiring, not
    # state -- see link_entry). Drop it BEFORE mkdir -p: mkdir -p on a dangling
    # symlink fails.
    if [ -L "$target" ]; then rm -f "$target"; fi
    mkdir -p "$target"

    for dst in "$target"/* "$target"/.*; do
        name=${dst##*/}
        case "$name" in .|..) continue ;; esac
        adopt_entry "$dst" "$mount"
    done

    for src in "$mount"/* "$mount"/.*; do
        name=${src##*/}
        case "$name" in .|..) continue ;; esac
        link_entry "$src" "$target/$name"
    done
}

# Public API for the feature's links.sh, which sources this file and then calls
# link once per mount, mirroring the `mounts` block in devcontainer-feature.json.
link() {
    [ $# -eq 3 ] || { log "link: want 3 args, got $#: $*" >&2; exit 2; }
    case "$1" in
        dir)  link_dir  "$2" "$HOME/$3" ;;
        file) link_entry "$2" "$HOME/$3" ;;
        *)    log "link: unknown kind: $1" >&2; exit 2 ;;
    esac
}
