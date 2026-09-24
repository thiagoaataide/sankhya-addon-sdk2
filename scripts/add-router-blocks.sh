#!/usr/bin/env sh
# Insere bloco router (opção B) nas skills Studio que sobrepõem references/ GET.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STUDIO="$ROOT/skills/studio"

add_block() {
  skill=$1
  ref=$2
  file="$STUDIO/$skill/SKILL.md"
  [ -f "$file" ] || return 0
  if grep -q "Referência GET (router)" "$file" 2>/dev/null; then
    return 0
  fi
  block="
## Referência GET (router)

Antes de gerar código, leia também \`references/${ref}\` (skill instalada \`sankhya-addon-sdk\`, caminho no repo \`../../references/${ref}\`). Essa reference traz regras GET + doc developer.sankhya.com.br; **esta skill Studio** traz fluxo validado contra os jars — não repita nem contradiga a reference.

---
"
  # insert after first --- closing frontmatter
  awk -v block="$block" '
    /^---$/ { n++; print; if (n==2) { print block } next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

add_block entity "orm.md"
add_block controller "controller.md"
add_block repository "repository.md"
add_block mapstruct "mapstruct.md"
add_block "dependency-injection" "dependency-injection.md"
add_block value "value.md"
add_block type-adapter "type-adapters.md"
add_block controller-advice "controller-advice.md"
add_block macros "macros.md"
add_block before-load-listener "before-load-listener.md"

echo "Router blocks applied."
