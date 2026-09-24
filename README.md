# Skill: SDK Sankhya (Addon Studio 2.0)

Habilidade de agent para **Cursor**, **Claude Code** e **Codex** implementar add-ons no **SDK Sankhya novo** (JAPE + Guice + Bean Validation + MapStruct).

Repositório **completo**: skill router GET + **25 skills** DevCenter + **6 agents**. O catálogo [skillforge](https://github.com/GRUPO-GET/skillforge) referencia este repo como *git submodule*.

Documentação oficial:

- [Introdução ao SDK](https://developer.sankhya.com.br/docs/introducao-sdk-sankhya)
- [Conceitos fundamentais](https://developer.sankhya.com.br/docs/conceitos-fundamentais)
- [Getting started](https://developer.sankhya.com.br/docs/iniciando)

## O que a skill router faz

- Exige `br.com.sankhya.studio:gradle-plugin` **≥ 2.0.18** no `build.gradle` antes de gerar código.
- Impõe o framework novo: `@JapeEntity`, `@Repository`, `@Controller` (não o alias `@Service`), `@Inject` (Guice), `@Transactional`, `@Valid`.
- Bloqueia legado (`DynamicVO`, `JapeSession.open`, `ServiceBean`) e JPA/Spring Data.
- Abre só o arquivo de referência do componente em uso (controller, ORM, macros, AutoDD, sub-abas nativas, …).

Sobreposição com skills Studio: **opção B (router)** — ver [ARCHITECTURE.md](ARCHITECTURE.md) e §6 de [SKILL.md](SKILL.md).

## Estrutura

```text
SKILL.md + references/     # router GET (instalado como sankhya-addon-sdk)
skills/studio/             # 25 skills addon-studio
agents/addon-studio/       # 6 agents
scripts/sync-addon-studio.sh
install.sh
```

## Instalação

```sh
git clone git@github.com:GRUPO-GET/sankhya-addon-sdk2.git
cd sankhya-addon-sdk2
chmod +x install.sh
./install.sh /caminho/do/seu-addon   # ou ./install.sh ~
```

Instala **26 skills** + **6 agents** em `.cursor/`, `.claude/`, `.codex/`.

Pelo catálogo skillforge:

```sh
git clone --recurse-submodules git@github.com:GRUPO-GET/skillforge.git
cd skillforge
./install.sh /caminho/do/seu-addon
```

## Como usar

- Entrada SDK / CRUD / AutoDD: `/sankhya-addon-sdk` (Cursor/Claude) ou linguagem natural “SDK 2.0”.
- Artefato específico: `/entity`, `/database`, `/data-dictionary`, …
- Agents: arquivos em `.cursor/agents/` (ex.: `entity-architect.md`).

## Licença

MIT (router GET). Addon Studio incorporado: MIT — `third-party/addon-studio/LICENSE.upstream`.
