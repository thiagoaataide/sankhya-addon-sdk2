---
name: sankhya-addon-sdk
description: Orienta o agent a implementar add-ons Sankhya com o SDK Addon Studio 2.0 (JapeEntity, JapeRepository, @Controller, Guice, Bean Validation, MapStruct, AutoDD). Use ao criar, revisar ou refatorar addon Sankhya; ao editar build.gradle do studio, entidades JAPE, repositórios, controllers, dicionário de dados; ou quando o usuário mencionar SDK Sankhya, Addon Studio, JapeRepository, AutoDD, @Transactional ou gradle-plugin.
paths:
  - "**/*.java"
  - "**/build.gradle"
  - "**/build.gradle.kts"
  - "**/settings.gradle"
  - "**/datadictionary/**"
  - "**/dbscripts/**"
compatibility: Cursor, Claude Code, Codex. Sankhya Addon Studio 2.0.18+ (Java 8, WildFly/EJB, JAPE).
---

# SDK Sankhya — Addon Studio 2.0

Skill de entrada para **codar add-ons no framework novo** (inspirado em Spring + JPA, executado sobre JAPE). Não invente APIs. Não use JPA (`javax.persistence`, Hibernate, Spring Data). Não volte ao legado (`DynamicVO`, `JapeFactory.dao`, `JapeSession.open`, `ServiceBean`).

Fonte canônica: [Introdução ao SDK](https://developer.sankhya.com.br/docs/introducao-sdk-sankhya) e [Conceitos fundamentais](https://developer.sankhya.com.br/docs/conceitos-fundamentais).

## 0. Antes de gerar código

1. **Validar o plugin do Studio** — leia o `build.gradle` da raiz. Exija `br.com.sankhya.studio:gradle-plugin` **2.0.18 ou superior**. Sem isso, pare e corrija. Detalhes em [references/version-build.md](references/version-build.md).
2. Detecte prefixo de tabelas (`TDC`, `SGT`, …) e pacote-base do projeto. Se não houver padrão claro, pergunte.
3. Carregue **somente** o arquivo de referência do componente que estiver implementando (índice abaixo). Não carregue todos de uma vez.

## 1. Os quatro pilares

| Pilar | Anotação / API | Papel |
| --- | --- | --- |
| ORM JAPE | `@JapeEntity`, `@Id`, `@Column` | POJO no lugar de `DynamicVO` |
| DI (Guice) | `@Inject` no construtor | Nunca `javax.inject.Inject`; nunca `new` de componente gerenciado |
| Repositório | `@Repository` + `JapeRepository<ID, T>` | CRUD + `@Criteria` / `@NativeQuery` |
| Transação + validação | `@Transactional`, `@Valid` | Atomicidade e Bean Validation (JSR 303/380) |

Camadas:

```
@Controller (entrada HTTP, serviceName *ControllerSP)  — não o alias @Service
    → @Component (regra de negócio)
        → @Repository (persistência)
            → @JapeEntity (tabela)
DTO + MapStruct no controller; entidade nunca sai na API.
```

## 2. Regras duras

- **Java 8** estrito. Sem `var`, records, `List.of`, streams de API 9+.
- **JAPE, não JPA.** Pacotes `br.com.sankhya.studio.persistence.*` e `br.com.sankhya.sdk.data.repository.JapeRepository`.
- **`com.google.inject.Inject`**, nunca `javax.inject.Inject`.
- **`JapeRepository<ID, Entity>`** — ID primeiro. PK de tabela nativa Sankhya costuma ser `BigDecimal`; PK de tabela do addon costuma ser `Integer`/`Long`. Confira o padrão do projeto.
- **Query methods estilo Spring Data não existem.** `findByPlacaStartingWith` não é implementado. Use `@Criteria` ou `@NativeQuery`.
- **`@Delete` foi descontinuado.** DELETE/UPDATE em massa = `@Modifying` + `@NativeQuery`.
- **`@Parameter(name = "x")`** — forma posicional `@Parameter("x")` pode falhar na compilação. Prefira `name =`.
- **Critérios:** prefixe colunas com `this.` (`this.PLACA = :placa`).
- **Prefixo `AD_` é reservado.** Use o prefixo do projeto.
- Fontes `.java` / `.xml` / `.properties` em **ISO-8859-1** quando o projeto Addon Studio exigir.
- SQL portável Oracle + MSSQL via macros (`dbDate()`, `nullValue()`, …) — [references/macros.md](references/macros.md).

## 3. Fluxo padrão (CRUD)

1. Entidade `@JapeEntity` (e PK composta com `@Embeddable` se preciso).
2. **AutoDD** (`autoDD = true`): Table/NativeTable saem da `@JapeEntity` no build — **não** gere XML em `datadictionary/` para essa tabela. Views, menus, dashboards e telas **ainda** são XML manual. Ver [references/autodd.md](references/autodd.md).
3. Interface `@Repository`.
4. DTO de request com Bean Validation + DTO de response.
5. Mapper MapStruct (`componentModel = "cdi"`).
6. `@Component` com a regra.
7. `@Controller(serviceName = "...ControllerSP")` só orquestra — **não** use o alias `@Service`. Ver [references/controller.md](references/controller.md).
8. `@ControllerAdvice` para erros — nunca `try/catch` no controller.
9. Teste o controller com mock das dependências.

Snippet mínimo:

```java
@Controller(serviceName = "VeiculoControllerSP")
public class VeiculoController {
    private final VeiculoRepository repository;
    private final VeiculoMapper mapper;

    @Inject
    public VeiculoController(VeiculoRepository repository, VeiculoMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Transactional
    public VeiculoResponseDTO cadastrar(@Valid VeiculoRequestDTO dto) {
        Veiculo salvo = repository.save(mapper.toEntity(dto));
        return mapper.toResponse(salvo);
    }
}
```

## 4. Quando ler cada referência

| Tarefa | Arquivo |
| --- | --- |
| `build.gradle`, plugin, AutoDD/AutoDDL, appKey | [references/version-build.md](references/version-build.md) |
| `@Controller` (não alias `@Service`), padrão de orquestração, envelope JSON, `transactionType` | [references/controller.md](references/controller.md) |
| `@NotNull`, `@Digits`, `@AssertTrue`, `@Valid` | [references/bean-validation.md](references/bean-validation.md) |
| `@Inject`, `@Component`, ciclos (entrada HTTP = `@Controller`) | [references/dependency-injection.md](references/dependency-injection.md) |
| `@Transactional`, `TransactionType` | [references/transactional.md](references/transactional.md) |
| `@JapeEntity`, `@OneToMany` / `@ManyToOne` / `@OneToOne`, PK | [references/orm.md](references/orm.md) |
| `JapeRepository`, retornos, `@Criteria`, `@NativeQuery`, `@Modifying` | [references/repository.md](references/repository.md) |
| MapStruct (`@Mapper`), mapeamento DTO ↔ `@JapeEntity` | [references/mapstruct.md](references/mapstruct.md) |
| Adaptadores nativos (`BooleanAdapter`, `DateAdapter`, …) e `@GlobalTypeAdapter` | [references/type-adapters.md](references/type-adapters.md) |
| JUL/Log4J1 e logs remotos | [references/logging.md](references/logging.md) |
| `@Value` (eager/`Provider`, fontes, tipos, boas práticas, anti-patterns) | [references/value.md](references/value.md) |
| Erros globais | [references/controller-advice.md](references/controller-advice.md) |
| AutoDD vs AutoDDL; **não** XML de Table em `datadictionary` se `autoDD = true` | [references/autodd.md](references/autodd.md) |
| FK: quadro `@ManyToOne`/`@OneToOne` → `@JoinColumn(s)`; `@OneToMany` → `@Relationship`; PK composta | [references/foreign-keys.md](references/foreign-keys.md) |
| SQL Oracle+MSSQL | [references/macros.md](references/macros.md) |
| Filtro transversal antes do Finder | [references/before-load-listener.md](references/before-load-listener.md) |

## 5. Anti-patterns (proibido)

| Não faça | Faça |
| --- | --- |
| `DynamicVO` / `JapeFactory.dao("...")` | `@JapeEntity` + `@Repository` |
| `JapeSession.open()` / `close()` | `@Transactional` |
| `javax.persistence.*` / Spring Data | APIs `br.com.sankhya.studio.*` |
| `new VeiculoRepository()` | `@Inject` no construtor |
| Entidade na response do controller | DTO + MapStruct |
| `@Service(serviceName = "...")` em código novo | `@Controller(serviceName = "...ControllerSP")` |
| Lógica de negócio no `@Controller` | `@Component` |
| `try/catch` no controller | `@ControllerAdvice` |
| `javax.inject.Inject` | `com.google.inject.Inject` |
| Concatenar SQL (`"PLACA = '" + placa + "'"`) | `:parametro` nomeado |
| `@Delete` | `@Modifying` + `@NativeQuery` |
| Plugin Studio `1.x` ou `< 2.0.18` | `gradle-plugin` ≥ 2.0.18 |

## 6. Skills irmãs

Se o repositório já tiver o plugin [snk-devcenter/addon-studio](https://github.com/snk-devcenter/addon-studio) (`entity`, `data-dictionary`, `database`, `controller`, …), use-as para artefatos especializados (dbscript dual, XML de tela, encoding). Esta skill manda no **framework novo** e na versão do Studio. Não contradiga o padrão já existente no projeto.

## 7. Documentação oficial

- https://developer.sankhya.com.br/docs/introducao-sdk-sankhya
- https://developer.sankhya.com.br/docs/conceitos-fundamentais
- https://developer.sankhya.com.br/docs/iniciando
- Índice markdown: https://developer.sankhya.com.br/llms.txt
