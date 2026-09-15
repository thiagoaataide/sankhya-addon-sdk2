# Sub-abas filhas em telas nativas (SDK 2.18+)

Padrão validado em ambiente local: entidade **filha** do addon aparece como aba em tela **nativa** do Om (ex.: Tipo de Operação `TGFTOP` + tabela do addon `GET_DOCSUB`).

Relacionado: [autodd.md](autodd.md), [orm.md](orm.md), [foreign-keys.md](foreign-keys.md).

## Duas camadas (não confunda)

| Camada | Responsabilidade |
| --- | --- |
| **Java + AutoDD/AutoDDL** | Entidade, PK, FK, `parentInstance`, relacionamentos no dicionário gerado |
| **Ambiente Sankhya** | Aba visual na tela nativa, cache, unidade de dados |

`parentInstance` registra a filha no metadata, mas **não garante** a aba na UI sem configuração no ambiente (cadastro da aba, restart da unidade de dados, cache).

---

## 0. Pré-requisitos

- `br.com.sankhya.studio:gradle-plugin` **≥ 2.0.18** (fluxo abaixo validado com **2.18+**). Ver [version-build.md](version-build.md).
- Tabela **do addon** (prefixo do projeto, ex. `GET_`). **Nunca `AD_`.**
- `./gradlew clean deployAddon` após mudar entidades.

```groovy
addon {
    autoDD = true
    autoDDL = true
}
```

Com AutoDD: **não** crie XML manual de `<table>` para a filha em `datadictionary/` — duplica o que o SDK gera. Ver [autodd.md](autodd.md).

---

## 1. Entidade filha com `parentInstance`

```java
@JapeEntity(
    entity = "DocumentosSubsequentes",
    table = "GET_DOCSUB",
    description = "Documentos Subsequentes",
    parentInstance = "br.com.sankhya.fin.cad.tipooperacao"
)
public class DocumentosSubsequentes {
    // ...
}
```

- `parentInstance` = identificador **real** da instância nativa pai no Om.
- **Não** troque pelo nome da classe Java sem conferir o XML gerado e o ambiente alvo.
- Exemplo validado: `br.com.sankhya.fin.cad.tipooperacao` (Tipo de Operação).

---

## 2. Pai nativo (`isNativeTable` + `isNativeInstance`)

```java
@JapeEntity(
    entity = "TipoOperacao",
    table = "TGFTOP",
    description = "Tipo de Operação",
    isNativeTable = true,
    isNativeInstance = true
)
public class TipoOperacao {

    @Id
    private TipoOperacaoId id;

    @OneToMany(
        relationship = {
            @Relationship(fromField = "CODTIPOPER", toField = "CODTIPOPER"),
            @Relationship(fromField = "DHALTER", toField = "DHALTER")
        }
    )
    private List<DocumentosSubsequentes> documentosSubsequentes;
}
```

Regra de mapeamento (igual [foreign-keys.md](foreign-keys.md)):

```text
Pai:   @OneToMany + @Relationship (uma entrada por coluna do vínculo)
Filho: @ManyToOne + @JoinColumn(s)
```

PK **composta** no pai: **todas** as colunas do vínculo entram em `@Relationship` e em `@JoinColumns` no filho.

---

## 3. PK composta da filha + sequência (`NUNICO`)

Exemplo de chave: `CODTIPOPER` + `DHALTER` + `NUNICO`.

```java
@Embeddable
public class DocumentosSubsequentesId implements Serializable {

    @Column(name = "CODTIPOPER", dataType = DataType.INTEGER, description = "Cód. tipo operação")
    private Long codTipOper;

    @Column(name = "DHALTER", dataType = DataType.DATE, description = "Data alteração")
    private Timestamp dhAlter;

    @GeneratedValue(strategy = GeneratedValue.GenerationType.AUTO)
    @Column(name = "NUNICO", dataType = DataType.INTEGER, description = "Número único")
    private Long nuUnico;

    // equals + hashCode obrigatórios
}
```

- `@GeneratedValue(AUTO)` no **`NUNICO` dentro do `@Embeddable`** — o JAPE gera o valor antes do `INSERT`.
- Sem isso: `NUNICO` null → **`ORA-01400`**.
- Metadata esperado (gerado, não editar): `sequenceType="A"` e `sequenceField="NUNICO"` na table.

Na entidade filha:

```java
@Id
private DocumentosSubsequentesId id;
```

---

## 4. FK filha → pai (`@JoinColumns`)

```java
@ManyToOne
@JoinColumns({
    @JoinColumn(
        name = "CODTIPOPER",
        referencedColumnName = "CODTIPOPER",
        dataType = DataType.INTEGER,
        description = "Cód. tipo operação"
    ),
    @JoinColumn(
        name = "DHALTER",
        referencedColumnName = "DHALTER",
        dataType = DataType.DATE,
        description = "Data alteração"
    )
})
private TipoOperacao tipoOperacao;
```

`description` (e `dataType` na FK) são **obrigatórios** com AutoDD.

---

## 5. Ligação a outra entidade nativa (pesquisa)

Produto padrão na filha → instância nativa `TGFPRO`:

```java
@JapeEntity(
    entity = "Produto",
    table = "TGFPRO",
    description = "Produto",
    isNativeTable = true,
    isNativeInstance = true
)
public class Produto {
    @Id
    @Column(name = "CODPROD", dataType = DataType.INTEGER, description = "Código produto")
    private Long codProd;
}
```

Na filha:

```java
@ManyToOne
@JoinColumn(
    name = "CODPRODPAD",
    referencedColumnName = "CODPROD",
    description = "Produto padrão",
    targetInstance = "Produto",
    targetField = "CODPROD",
    targetType = DataType.INTEGER
)
private Produto produtoPadrao;
```

Se a pesquisa não abrir: confira `targetInstance`, `targetField` e a entidade nativa `Produto`.

---

## 6. Proibido no relacionamento pai/filho

| Não | Motivo |
| --- | --- |
| `@Expression` no lugar de `@JoinColumns` / `@Relationship` | SQL com `#type.sql#` → **`ORA-00911`** |
| `@JoinColumn` no `@OneToMany` | Use `relationship` — [foreign-keys.md](foreign-keys.md) |
| XML manual de table da filha com `autoDD = true` | Regressão; use Java + AutoDD |

---

## 7. Validar metadata **gerado** (somente leitura)

Após build, **confira** sem editar:

```text
model/buildGradle/studioGenerated/datadictionary/GET_DOCSUB.xml
model/buildGradle/studioGenerated/datadictionary/TGFTOP_TipoOperacao_extension.xml
build/dist/datadictionary/metadata.xml
```

Deve existir:

```xml
<instance
    name="DocumentosSubsequentes"
    parentInstance="br.com.sankhya.fin.cad.tipooperacao">
```

Relacionamentos esperados:

```xml
<relation fromEntity="TipoOperacao" toEntity="DocumentosSubsequentes"/>
<relation fromEntity="DocumentosSubsequentes" toEntity="TipoOperacao"/>
<relation fromEntity="DocumentosSubsequentes" toEntity="Produto"/>
```

`features-summary.json` com `screens: []` e `dynamicForms: []` **não invalida** a filha — só indica que o addon não tem tela/dynamic form **próprio** para essa entidade.

---

## 8. Expor a aba na tela nativa (ambiente)

O Java + AutoDD registram instância e ligações. A **aba visual** costuma exigir passos no Sankhya:

1. Cadastrar/configurar a aba na tela da tabela nativa (ex. `TGFTOP`).
2. Associar a aba à instância filha (`DocumentosSubsequentes`).
3. Reiniciar a unidade de dados da tela.
4. Limpar cache ou recarregar o servidor.

**Não** crie menu, tela independente ou `dynamicForm` só para a entidade filha.

Se `parentInstance` não bastar no ambiente alvo, fallback **mínimo** em XML autorizado (mestre/detalhe) — **sem** redefinir table, campos, PK ou DDL. Preferência continua sendo Java + metadata gerado.

---

## Diagnóstico rápido

| Sintoma | Verificação |
| --- | --- |
| Tabela no banco, sem dicionário | Metadata gerado; migração/deploy do addon |
| Aba não aparece | `parentInstance`, cadastro da aba, cache/unidade de dados |
| **`ORA-00911`** | Remover `@Expression` do relacionamento |
| **`ORA-01400`** em `NUNICO` | `@GeneratedValue(AUTO)` no campo do `@Embeddable` |
| Produto sem pesquisa | `targetInstance`, `targetField`, entidade nativa `Produto` |
| FK composta errada | Ordem e colunas em `@Relationship` e `@JoinColumns` — [foreign-keys.md](foreign-keys.md) |

---

## Não editar manualmente

Artefatos de build/runtime — alteração só no **Java** ou configuração **persistida no ambiente**:

- `model/buildGradle/studioGenerated/**`
- `build/dist/**`
- `metadata.xml` expandido no VFS do WildFly (`standalone/tmp/vfs/**`)

---

## Checklist para o agent

1. `autoDD` + `autoDDL` no `build.gradle`.
2. Filha: tabela do addon + `parentInstance` validado no XML gerado.
3. Pai: `isNativeTable` + `isNativeInstance` + `@OneToMany` + `@Relationship`.
4. Filha: `@Embeddable` PK + `@GeneratedValue` na sequência + `@ManyToOne` + `@JoinColumns`.
5. Nativas auxiliares (ex. `Produto`): `@JapeEntity` nativa + `@JoinColumn` com `targetInstance` / `targetField`.
6. Build → ler metadata gerado → orientar configuração de aba no ambiente.
7. Sem `@Expression` nos vínculos; sem XML de table duplicado em `datadictionary/`.
