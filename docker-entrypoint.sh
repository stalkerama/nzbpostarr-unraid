#!/bin/sh
set -eu

PUID="${PUID:-99}"
PGID="${PGID:-100}"
CONFIG_FILE="${NZBPOSTARR_CONFIG:-/config/config.yaml}"
APP_ROOT="/opt/nzbpostarr"

mkdir -p /config/data "$APP_ROOT/.local"

# Seed the persistent config from the upstream project's own defaults.
# Only the example base path is adapted to the container's /data mount.
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    sed "s#base_folder: '/path/to/usenet'#base_folder: '/data'#" \
        "$APP_ROOT/core/config.defaults.yaml" > "$CONFIG_FILE"
    echo "[container] Created $CONFIG_FILE from upstream defaults (base_folder=/data)."
fi

# Upstream stores history, generated NZBs and temporary runtime state under
# APP_ROOT/data. Persist that directory through /config without changing source.
if [ -e "$APP_ROOT/data" ] && [ ! -L "$APP_ROOT/data" ]; then
    if [ -d "$APP_ROOT/data" ] && [ "$(ls -A "$APP_ROOT/data" 2>/dev/null || true)" ]; then
        cp -a "$APP_ROOT/data/." /config/data/
    fi
    rm -rf "$APP_ROOT/data"
fi

if [ ! -L "$APP_ROOT/data" ]; then
    ln -s /config/data "$APP_ROOT/data"
fi

chown -R "$PUID:$PGID" /config "$APP_ROOT/.local"

export HOME=/config
export NZBPOSTARR_CONFIG="$CONFIG_FILE"

cd "$APP_ROOT"
exec gosu "$PUID:$PGID" python main.py --direct --host 0.0.0.0 --port 8000
