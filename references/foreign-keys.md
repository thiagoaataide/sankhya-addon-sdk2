# Foreign keys compostas

Doc: https://developer.sankhya.com.br/docs/foreign-keys-compostas

FK composta = várias colunas na tabela local apontando para a **PK composta** da outra tabela. No SDK isso é `@JoinColumn` / `@JoinColumns` **ou** `relationship` / `@Relationship` — conforme a cardinalidade. Não misture os dois mecanismos no mesmo campo.

## `@JoinColumn` / `@JoinColumns` só em `@ManyToOne` e `@OneToOne`

Para `@OneToMany`, use o atributo `relationship` da própria anotação. Nunca `@JoinColumn` no pai.

| Relacionamento | Mapeamento de colunas |
| --- | --- |
| `@ManyToOne` | `@JoinColumn` ou `@JoinColumns` |
| `@OneToOne` | `@JoinColumn` ou `@JoinColumns` |
| `@OneToMany` | `relationship = {@Relationship(...)}` |

- `@JoinColumn` — FK de **uma** coluna.
- `@JoinColumns({ ... })` — FK de **duas ou mais** colunas (PK composta no destino).
- `description` em cada `@JoinColumn` é **obrigatório** com AutoDD. Ver [autodd.md](autodd.md).
- Relacionamentos simples (PK única): [orm.md](orm.md).

---

## Sintaxe

### `@JoinColumn` — FK simples (`@ManyToOne` / `@OneToOne`)

`name` = coluna FK **nesta** tabela. `referencedColumnName` = coluna PK na tabela referenciada.

```java
@ManyToOne
@JoinColumn(
    name = "CODPARC",                   // coluna FK na tabela local
    referencedColumnName = "CODPARC",   // coluna PK na tabela referenciada
    description = "Código do Parceiro"  // obrigatório com autoDD
)
private Parceiro parceiro;
```

O mesmo padrão vale em `@OneToOne` no lado que **guarda** a FK.

### `@JoinColumns` — FK composta (`@ManyToOne` / `@OneToOne`)

Um `@JoinColumn` por coluna da PK composta. A **ordem** deve ser a mesma do `@Embeddable` da entidade destino.

```java
@ManyToOne
@JoinColumns({
    @JoinColumn(name = "NUNOTA", referencedColumnName = "NUNOTA", description = "Num. Nota"),
    @JoinColumn(name = "SEQUENCIA", referencedColumnName = "SEQUENCIA", description = "Sequencia Item")
})
private ItemNota itemNota;
```

### `@Relationship` — só em `@OneToMany`

`fromField` = coluna no **pai**; `toField` = coluna no **filho**. Uma entrada por coluna da ligação. Proibido `@JoinColumn` / `@JoinColumns` neste campo.

PK simples:

```java
@OneToMany(
    cascade = Cascade.ALL,
    relationship = {
        @Relationship(fromField = "NUNOTA", toField = "NUNOTA")
    }
)
private List<ItemPedido> itens;
```

PK composta no pai — um `@Relationship` por coluna (espelha o `@JoinColumns` do filho):

```java
@OneToMany(
    cascade = {Cascade.CREATE, Cascade.MERGE},
    relationship = {
        @Relationship(fromField = "COL1", toField = "FK_PAI_COL1"),
        @Relationship(fromField = "COL2", toField = "FK_PAI_COL2")
    }
)
private List<Filha> filhas;
```

---

## Exemplos (copie o padrão)

### 1. PK simples referenciando PK composta (`@OneToOne` + `@JoinColumns`)

A entidade local tem PK de uma coluna. A FK aponta para duas colunas da PK composta do destino.

```java
@JapeEntity(entity = "ChaveSimples", table = "TB_CHAVE_SIMPLES")
public class ChaveSimples {
    @Id
    @Column(name = "ID")
    private Long id;

    @OneToOne
    @JoinColumns({
        @JoinColumn(name = "FK_COL1", referencedColumnName = "COL1", description = "Coluna 1"),
        @JoinColumn(name = "FK_COL2", referencedColumnName = "COL2", description = "Coluna 2")
    })
    private ChaveComposta chaveComposta;
}

@Embeddable
public class ChaveCompostaId implements Serializable {
    @Column(name = "COL1")
    private Long col1;

    @Column(name = "COL2")
    private Long col2;
    // equals + hashCode obrigatórios
}

@JapeEntity(entity = "ChaveComposta", table = "TB_CHAVE_COMPOSTA")
public class ChaveComposta {
    @Id
    private ChaveCompostaId id;
}
```

### 2. PK composta referenciando PK composta (`@ManyToOne` + `@JoinColumns`)

As duas entidades têm `@Embeddable`. As colunas FK **não** precisam ter o mesmo nome da PK destino — `name` é local, `referencedColumnName` é a PK da outra tabela.

```java
@Embeddable
public class ChaveComposta2Id implements Serializable {
    @Column(name = "COL1")
    private Long col1;

    @Column(name = "COL2")
    private Long col2;
    // equals + hashCode obrigatórios
}

@JapeEntity(entity = "ChaveComposta2", table = "TB_CHAVE_COMPOSTA_2")
public class ChaveComposta2 {
    @Id
    private ChaveComposta2Id id;

    @ManyToOne
    @JoinColumns({
        @JoinColumn(name = "FK_TB1_COL1", referencedColumnName = "COL1", description = "FK Col1"),
        @JoinColumn(name = "FK_TB1_COL2", referencedColumnName = "COL2", description = "FK Col2")
    })
    private ChaveComposta1 chaveComposta1;
}
```

`ChaveComposta1` segue o mesmo `@Embeddable` do exemplo 1 (`COL1` + `COL2`).

### 3. `@OneToMany` com pai de PK composta

A FK mora no **filho** (`@ManyToOne` + `@JoinColumns`). No **pai**, a coleção usa `relationship` — nunca `@JoinColumn`. Prefira `Cascade.CREATE` + `Cascade.MERGE` em vez de `Cascade.ALL`.

```java
@Embeddable
public class PaiId implements Serializable {
    @Column(name = "COL1")
    private Long col1;

    @Column(name = "COL2")
    private Long col2;
    // equals + hashCode obrigatórios
}

@JapeEntity(entity = "Pai", table = "TB_PAI")
public class Pai {
    @Id
    private PaiId id;

    @OneToMany(
        cascade = {Cascade.CREATE, Cascade.MERGE},
        relationship = {
            @Relationship(fromField = "COL1", toField = "FK_PAI_COL1"),
            @Relationship(fromField = "COL2", toField = "FK_PAI_COL2")
        }
    )
    private List<Filha> filhas;
}

@JapeEntity(entity = "Filha", table = "TB_FILHA")
public class Filha {
    @Id
    @Column(name = "ID")
    private Long id;

    @ManyToOne
    @JoinColumns({
        @JoinColumn(name = "FK_PAI_COL1", referencedColumnName = "COL1", description = "FK Pai Col1"),
        @JoinColumn(name = "FK_PAI_COL2", referencedColumnName = "COL2", description = "FK Pai Col2")
    })
    private Pai pai;
}
```

---

## Boas práticas

- Nomes descritivos nas colunas FK — `CODEMP_CONTRATO` melhor que `EMP`.
- A mesma ordem em `@JoinColumns`, `@Relationship` e no `@Embeddable` da PK destino.
- Prefira `Cascade.CREATE` e `Cascade.MERGE` a `Cascade.ALL` em FKs compostas.
- `@ToString.Exclude` no lado inverso (Lombok) — evita `StackOverflowError`.
- Não inicialize a coleção do `@OneToMany` (`= new ArrayList<>()` quebra lazy). Ver [orm.md](orm.md).

## Anti-pattern

| Não | Sim |
| --- | --- |
| `@JoinColumn` no campo `@OneToMany` | `relationship = {@Relationship(...)}` no pai; FK no filho |
| Um `@JoinColumn` para PK composta | `@JoinColumns({ @JoinColumn, @JoinColumn })` |
| Ordem diferente entre `@Embeddable` e `@JoinColumns` | mesma ordem das colunas da PK |
| `Cascade.ALL` por default em FK composta | `Cascade.CREATE` + `Cascade.MERGE` |
