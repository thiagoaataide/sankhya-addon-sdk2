# Skill: SDK Sankhya (Addon Studio 2.0)

Habilidade de agent para **Cursor**, **Claude Code** e **Codex** implementar add-ons no **SDK Sankhya novo** (JAPE + Guice + Bean Validation + MapStruct).

Este repositório **é a skill**. O catálogo [skillforge](https://github.com/GRUPO-GET/skillforge) inclui este repo como *git submodule*.

Baseada na documentação oficial:

- [Introdução ao SDK](https://developer.sankhya.com.br/docs/introducao-sdk-sankhya)
- [Conceitos fundamentais](https://developer.sankhya.com.br/docs/conceitos-fundamentais)
- [Getting started](https://developer.sankhya.com.br/docs/iniciando)

Complementa (não substitui) o plugin [snk-devcenter/addon-studio](https://github.com/snk-devcenter/addon-studio) quando ele já estiver no projeto.

## O que a skill faz

- Exige `br.com.sankhya.studio:gradle-plugin` **≥ 2.0.18** no `build.gradle` antes de gerar código.
- Impõe o framework novo: `@JapeEntity`, `@Repository`, `@Controller` (não o alias `@Service`), `@Inject` (Guice), `@Transactional`, `@Valid`.
- Bloqueia legado (`DynamicVO`, `JapeSession.open`, `ServiceBean`) e JPA/Spring Data.
- Abre só o arquivo de referência do componente em uso (controller, ORM, macros, AutoDD, …).

## Estrutura

```text
SKILL.md                          # entrada (sempre)
references/                       # sob demanda
install.sh                        # copia para o addon
```

## Instalação em um projeto de addon

```sh
git clone git@github.com:GRUPO-GET/sankhya-addon-sdk2.git
cd sankhya-addon-sdk2
./install.sh /caminho/do/seu-addon
```

O script copia a skill para:

| Agent | Destino no addon |
| --- | --- |
| Cursor | `.cursor/skills/sankhya-addon-sdk/` |
| Claude Code | `.claude/skills/sankhya-addon-sdk/` |
| Codex | `.codex/skills/sankhya-addon-sdk/` |

No Cursor, se a skill aparecer duplicada, mantenha só `.cursor/skills/`.

Pelo catálogo skillforge:

```sh
git clone --recurse-submodules git@github.com:thiagoaataide/-skillforge.git
cd -- -skillforge
./install.sh /caminho/do/seu-addon
```

## Como usar

Linguagem natural:

> Crie o controller, o repositório e a entidade JAPE desta tabela no padrão do SDK Sankhya 2.0.

Invocação explícita:

- Cursor / Claude: `/sankhya-addon-sdk`
- Codex: `$sankhya-addon-sdk`

## Premissas

- Java 8, WildFly/EJB, encoding ISO-8859-1 quando o Studio exigir.
- SQL portável Oracle + SQL Server via macros (`dbDate()`, `nullValue()`, …).
- Prefixo de tabelas e pacote-base vêm do projeto; se não houver padrão, o agent pergunta.
- AutoDD gera Table/NativeTable; menus, views e dashboards continuam no dicionário XML.

## Licença

MIT.
