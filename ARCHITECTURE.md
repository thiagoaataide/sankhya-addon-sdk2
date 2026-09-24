# Arquitetura — sankhya-addon-sdk2

Repositório **único** para agentes que codam addons Sankhya Addon Studio 2.0 (GET + DevCenter incorporado).

## Opção B — Router

| Camada | Onde | Papel |
| --- | --- | --- |
| **Router** | `SKILL.md` + `references/` | Entrada GET: regras duras, doc developer.sankhya.com.br, índice por tarefa |
| **Studio** | `skills/studio/<nome>/` | Skills granulares (XML, dbscript, JSP, …); fluxo validado contra jars do plugin |
| **Agents** | `agents/addon-studio/` | Sub-agentes multi-artefato (entity-architect, dbscript-builder, …) |

Sobreposição (`entity`, `controller`, `repository`, …): **não** duplicar prose longa nas skills Studio. Cada skill sobreposta inclui bloco **Referência GET (router)** apontando para `references/*.md`. O agent lê a reference GET e a skill Studio; a Studio não contradiz a reference.

### Mapeamento Studio → reference GET

| Skill Studio | Reference |
| --- | --- |
| `entity` | `orm.md` |
| `controller` | `controller.md` |
| `repository` | `repository.md` |
| `mapstruct` | `mapstruct.md` |
| `dependency-injection` | `dependency-injection.md` |
| `value` | `value.md` |
| `type-adapter` | `type-adapters.md` |
| `controller-advice` | `controller-advice.md` |
| `macros` | `macros.md` |
| `before-load-listener` | `before-load-listener.md` |

Skills **sem** par GET dedicado (ex.: `data-dictionary`, `database`, `sankhya-js`) vivem só em `skills/studio/`; o router indica quando invocá-las (§6 de `SKILL.md`).

## Layout

```text
SKILL.md
references/
ARCHITECTURE.md
install.sh
scripts/
  add-router-blocks.sh    # pós-sync ou pós-cópia manual
  sync-addon-studio.sh      # pull upstream snk-devcenter/addon-studio
skills/studio/              # 25 skills (MIT upstream)
agents/addon-studio/        # 6 .md + codex/*.toml
third-party/addon-studio/   # UPSTREAM_*, LICENSE.upstream, README
```

## skillforge (catálogo)

[skillforge](https://github.com/GRUPO-GET/skillforge) mantém apenas submódulo `skills/sankhya-addon-sdk2` + `install.sh` que delega para este repo. **Não** há `vendor/addon-studio` no catálogo.

## Atualizar upstream DevCenter

```sh
./scripts/sync-addon-studio.sh
git diff
git commit -am "chore: sync addon-studio upstream"
```
