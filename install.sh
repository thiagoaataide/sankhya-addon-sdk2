#!/usr/bin/env sh
set -eu

if [ "${1:-}" = "" ]; then
  echo "Uso: ./install.sh /caminho/do/projeto-addon"
  echo "Copia esta skill para .cursor/skills, .claude/skills e .codex/skills como sankhya-addon-sdk."
  exit 1
fi

TARGET=$1
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ ! -f "$ROOT/SKILL.md" ]; then
  echo "SKILL.md não encontrado em $ROOT"
  exit 1
fi

for dest in .cursor/skills .claude/skills .codex/skills; do
  mkdir -p "$TARGET/$dest"
  rm -rf "$TARGET/$dest/sankhya-addon-sdk"
  mkdir -p "$TARGET/$dest/sankhya-addon-sdk"
  cp -R "$ROOT/SKILL.md" "$ROOT/references" "$TARGET/$dest/sankhya-addon-sdk/"
  echo "Instalado em $TARGET/$dest/sankhya-addon-sdk"
done
