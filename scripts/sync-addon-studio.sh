#!/usr/bin/env sh
# Atualiza skills/studio e agents/addon-studio a partir de snk-devcenter/addon-studio.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=${TMPDIR:-/tmp}/addon-studio-sync-$$
UPSTREAM=https://github.com/snk-devcenter/addon-studio.git
PLUGIN_PATH=plugins/addon-studio

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "Clonando $UPSTREAM (depth 1)…"
git clone --depth=1 "$UPSTREAM" "$TMP"

SRC_SKILLS="$TMP/$PLUGIN_PATH/skills"
SRC_AGENTS="$TMP/$PLUGIN_PATH/agents"
if [ ! -d "$SRC_SKILLS/entity" ]; then
  echo "Layout upstream inesperado em $PLUGIN_PATH/skills"
  exit 1
fi

echo "Copiando skills → $ROOT/skills/studio/"
rm -rf "$ROOT/skills/studio"
mkdir -p "$ROOT/skills/studio"
cp -R "$SRC_SKILLS"/* "$ROOT/skills/studio/"

echo "Copiando agents → $ROOT/agents/addon-studio/"
rm -rf "$ROOT/agents/addon-studio"
mkdir -p "$ROOT/agents/addon-studio"
cp -R "$SRC_AGENTS"/* "$ROOT/agents/addon-studio/"

VERSION=$(git -C "$TMP" describe --tags --always 2>/dev/null || echo unknown)
COMMIT=$(git -C "$TMP" rev-parse HEAD)
echo "$VERSION" > "$ROOT/third-party/addon-studio/UPSTREAM_VERSION"
echo "$COMMIT" > "$ROOT/third-party/addon-studio/UPSTREAM_COMMIT"

echo "Reaplicando blocos router (opção B)…"
"$ROOT/scripts/add-router-blocks.sh"

echo "Upstream: $VERSION @ $COMMIT"
echo "Revise diff e commit."
