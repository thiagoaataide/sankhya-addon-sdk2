#!/usr/bin/env sh
# Instala skill router GET + 25 skills Studio + 6 agents addon-studio.
set -eu

if [ "${1:-}" = "" ]; then
  echo "Uso: ./install.sh /caminho/do/projeto-addon   # ou ./install.sh ~"
  echo ""
  echo "Instala:"
  echo "  - sankhya-addon-sdk (SKILL.md + references/ — router GET, opção B)"
  echo "  - 25 skills em skills/studio/* (snk-devcenter/addon-studio incorporado)"
  echo "  - 6 agents em agents/addon-studio/"
  exit 1
fi

TARGET=$1
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STUDIO_SKILLS="$ROOT/skills/studio"
STUDIO_AGENTS="$ROOT/agents/addon-studio"
STUDIO_CODEX_AGENTS="$STUDIO_AGENTS/codex"

if [ ! -f "$ROOT/SKILL.md" ]; then
  echo "SKILL.md não encontrado em $ROOT"
  exit 1
fi

if [ ! -d "$STUDIO_SKILLS/entity" ]; then
  echo "skills/studio/ ausente. Rode scripts/sync-addon-studio.sh ou clone completo."
  exit 1
fi

install_skill_dir() {
  src_dir=$1
  skill_name=$2
  for agent_root in .cursor/skills .claude/skills .codex/skills; do
    dest="$TARGET/$agent_root/$skill_name"
    mkdir -p "$dest"
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -R "$src_dir"/. "$dest/"
    echo "  skill → $dest"
  done
}

echo "→ sankhya-addon-sdk (router + references/)"
for agent_root in .cursor/skills .claude/skills .codex/skills; do
  dest="$TARGET/$agent_root/sankhya-addon-sdk"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$ROOT/SKILL.md" "$dest/"
  cp -R "$ROOT/references" "$dest/"
  echo "  skill → $dest"
done

echo "→ addon-studio (25 skills)"
for skill_path in "$STUDIO_SKILLS"/*/; do
  [ -f "${skill_path}SKILL.md" ] || continue
  skill_name=$(basename "$skill_path")
  install_skill_dir "$skill_path" "$skill_name"
done

echo "→ agents addon-studio (6 especialistas)"
for agent_root in .cursor/agents .claude/agents; do
  dest_dir="$TARGET/$agent_root"
  mkdir -p "$dest_dir"
  for agent_md in "$STUDIO_AGENTS"/*.md; do
    [ -f "$agent_md" ] || continue
    cp "$agent_md" "$dest_dir/"
    echo "  agent → $dest_dir/$(basename "$agent_md")"
  done
done

if [ -d "$STUDIO_CODEX_AGENTS" ]; then
  codex_dest="$TARGET/.codex/agents"
  mkdir -p "$codex_dest"
  for agent_toml in "$STUDIO_CODEX_AGENTS"/*.toml; do
    [ -f "$agent_toml" ] || continue
    cp "$agent_toml" "$codex_dest/"
    echo "  codex agent → $codex_dest/$(basename "$agent_toml")"
  done
fi

echo ""
echo "Pronto em: $TARGET"
echo "Router GET: /sankhya-addon-sdk — references/ + tabela Studio em SKILL.md §6."
echo "Studio: /entity, /database, … (nome da pasta)."
