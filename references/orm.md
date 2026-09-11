# ORM JAPE (`@JapeEntity`)

Doc: https://developer.sankhya.com.br/docs/mapeamento-relacional

Não use `javax.persistence.*`. Anotações: `br.com.sankhya.studio.persistence.*`.

A tabela/entidade ainda precisa existir no dicionário (XML manual **ou** AutoDD). Ver [autodd.md](autodd.md). FK composta: [foreign-keys.md](foreign-keys.md).

```java
@Data
@JapeEntity(entity = "Veiculo", table = "TGFVEI")
public class Veiculo {
    @Id
    @Column(name = "CODVEICULO")
    private Long id;

    @Column(name = "PLACA")
    private String placa;

    @Column(name = "ATIVO")
    private boolean ativo;
}
```

Tipos de coluna: primitivos, wrappers, `BigDecimal`, `String`, `Timestamp`, `LocalDate`, `LocalDateTime`, enums. Boolean JAPE grava `S`/`N` via adapter nativo. Nunca prefixo `AD_`.

## PK composta

```java
@Embeddable
public class ItemNotaPK implements Serializable {
    @Column(name = "NUNOTA")
    private Long numeroNota;
    @Column(name = "SEQUENCIA")
    private Integer sequencia;
    // equals + hashCode obrigatórios
}

@JapeEntity(entity = "ItemNota", table = "TGFITE")
public class ItemNota {
    @Id
    private ItemNotaPK id;
}
```

---

## Relacionamentos — mapa rápido

O SDK documenta **três** relacionamentos. Cada um tem anotação e mapeamento de coluna **diferentes**. Não misture.

| Relacionamento | Mapeamento de colunas | Quem tem a FK |
| --- | --- | --- |
| `@ManyToOne` | `@JoinColumn` ou `@JoinColumns` (**obrigatório**) | este lado |
| `@OneToOne` | `@JoinColumn` ou `@JoinColumns` (**obrigatório**) | o lado que guarda a FK |
| `@OneToMany` | `relationship = {@Relationship(...)}` | lado **muitos** (filho) |

Proibido em **qualquer** relacionamento: `@Column` no mesmo campo.  
Proibido em `@OneToMany`: `@JoinColumn` / `@JoinColumns`.  
`@ToString.Exclude` no lado inverso (Lombok) — evita `StackOverflowError`.  
`description` em `@JoinColumn` é obrigatório com AutoDD.  
PK composta, `@JoinColumns` e `@Relationship` com várias colunas: [foreign-keys.md](foreign-keys.md).

---

## 1. Um-para-muitos — `@OneToMany`

Um pai, vários filhos. Tipo do campo: `List` ou `Set` da entidade filha.

**Exemplo:** um `Pedido` tem vários `ItemPedido`.

```java
@JapeEntity(entity = "CabecalhoNota", table = "TGFCAB")
public class Pedido {
    @Id
    @Column(name = "NUNOTA")
    private Long numeroNota;

    @OneToMany(
        cascade = Cascade.ALL,
        relationship = {
            @Relationship(fromField = "NUNOTA", toField = "NUNOTA")
        }
    )
    private List<ItemPedido> itens;
}
```

Regras:

- `fromField` = coluna no **pai**; `toField` = coluna no **filho**.
- Não inicialize a coleção (`= new ArrayList<>()` quebra lazy).
- Lado inverso opcional: `@ManyToOne` no filho (seção seguinte).

---

## 2. Muitos-para-um — `@ManyToOne`

Vários registros apontam para **um**. Este lado **detém a FK**.

**Exemplo:** vários `Produto`s pertencem a uma `CategoriaProduto`.

```java
@JapeEntity(entity = "Produto", table = "TGFPRO")
public class Produto {
    @Id
    @Column(name = "CODPROD")
    private Long codigo;

    @ManyToOne
    @ToString.Exclude
    @JoinColumn(
        name = "CODGRUPOPROD",
        referencedColumnName = "CODGRUPOPROD",
        description = "Código do Grupo de Produto"
    )
    private CategoriaProduto categoria;
}

@JapeEntity(entity = "GrupoProduto", table = "TGFGRU")
public class CategoriaProduto {
    @Id
    @Column(name = "CODGRUPOPROD")
    private Long codigo;

    @OneToMany(
        relationship = {
            @Relationship(fromField = "CODGRUPOPROD", toField = "CODGRUPOPROD")
        }
    )
    private List<Produto> produtos;
}
```

Regras:

- `@JoinColumn` / `@JoinColumns` é **obrigatório**.
- `name` = coluna FK **nesta** tabela; `referencedColumnName` = PK da outra.
- Bidirecional: o inverso é `@OneToMany` na categoria, com `relationship`.

Par pai/filho do pedido (lado filho):

```java
@JapeEntity(entity = "ItemPedido", table = "TGFITE")
public class ItemPedido {
    @Id
    @Column(name = "ID")
    private Long id;

    @ManyToOne
    @ToString.Exclude
    @JoinColumn(
        name = "NUNOTA",
        referencedColumnName = "NUNOTA",
        description = "Número da Nota"
    )
    private Pedido pedido;
}
```

Helpers no pai, para os dois lados ficarem consistentes:

```java
public void addItem(ItemPedido item) {
    this.itens.add(item);
    item.setPedido(this);
}

public void removeItem(ItemPedido item) {
    this.itens.remove(item);
    item.setPedido(null);
}
```

---

## 3. Um-para-um — `@OneToOne`

Um registro associado a **exatamente um** da outra entidade.

**Exemplo:** um `Usuario` tem um `PerfilUsuario`.

```java
@JapeEntity(entity = "Usuario", table = "TSIUSU")
public class Usuario {
    @Id
    @Column(name = "CODUSU")
    private Long codigo;

    @OneToOne
    @JoinColumn(
        name = "CODIGO_PERFIL",
        referencedColumnName = "CODIGO_PERFIL",
        description = "Código Perfil"
    )
    private PerfilUsuario perfil;
}

@JapeEntity(entity = "PerfilUsuario", table = "AD_PERFILUSU")
public class PerfilUsuario {
    @Id
    @Column(name = "CODPERFILUSU")
    private Long codigo;

    @OneToOne
    @ToString.Exclude
    @JoinColumn(
        name = "CODUSU",
        referencedColumnName = "CODUSU",
        description = "Código Usuário"
    )
    private Usuario usuario;
}
```

Regras:

- `@JoinColumn` / `@JoinColumns` é **obrigatório** no lado que tem a FK.
- Inverso opcional, também `@OneToOne`, com `@ToString.Exclude`.

## `reverseColumn`

Em `@OneToOne` e `@ManyToOne`, `reverseColumn` preenche a FK em `Cascade.MERGE`, `Cascade.UPDATE` e `Cascade.INSERT`. Sem ela, o Jape usa a primeira coluna da PK.

---

## Lazy loading

O SDK só documenta carregamento **lazy** entre entidades.

```java
@ManyToOne(fetchType = FetchType.LAZY)
@JoinColumn(
    name = "CODPARC",
    referencedColumnName = "CODPARC",
    description = "Código Cliente"
)
private Cliente cliente;
```

O acesso ao banco ocorre no **getter**. Até `getCliente()`, o campo permanece `null`.

- Errado: `if (pedido.cliente == null)`
- Correto: `if (pedido.getCliente() == null)`

`@Lazy` em **campo simples** (não `@Id`, não relacionamento). Gson serializa fields, não getters — não exponha entidade `@Lazy` no controller; use MapStruct → DTO. Ver [mapstruct.md](mapstruct.md).

```java
@Lazy
@ToString.Exclude
@Column(name = "CONTEUDO")
private Text conteudoGrande;
```

## TEXT_BOX e FILE

| DataType | Prefira | Alternativa |
| --- | --- | --- |
| `TEXT_BOX` | `br.com.sankhya.sdk.data.structures.Text` | `char[]` |
| `FILE` | `br.com.sankhya.sdk.data.structures.Binary` | `byte[]` |

```java
Text fromString = Text.of("teste");
Binary fromBytes = Binary.of(new byte[]{1, 2, 3});
Binary fromStream = Binary.of(inputStream);
```

## Cascade

Documente `cascade` na anotação. A doc oficial ainda diz que a **propagação efetiva** sai do dicionário XML (`insert`, `update`, `removeCascade`). Mapear na anotação prepara o código para quando o Studio honrar o atributo.

| Valor | Efeito |
| --- | --- |
| `Cascade.NONE` | padrão; salve cada entidade |
| `Cascade.CREATE` | persiste filhos novos com o pai |
| `Cascade.UPDATE` | sincroniza filhos |
| `Cascade.DELETE` | apaga filhos com o pai |
| `Cascade.MERGE` | vincula os dois lados |
| `Cascade.ALL` | CREATE + UPDATE + DELETE + MERGE |

XML equivalente a `Cascade.ALL`:

```xml
<relation entityName="EntidadeFilha" relation="OneToMany"
          insert="S" update="S" removeCascade="S">
    <fields>
        <field localName="ID" targetName="ENTIDADE_PAI_ID"/>
    </fields>
</relation>
```

## Orphan removal (`@OneToMany`)

| Estratégia | Efeito |
| --- | --- |
| `NONE` | não mexe no vínculo (padrão seguro em nativas) |
| `DETACH` | zera a FK do filho (`NULL`); **não** apaga o registro |

Exige pelo menos `Cascade.MERGE` (ou `ALL`). Uso incorreto perde vínculo sem querer.

```java
@OneToMany(
    cascade = Cascade.ALL,
    orphanRemovalStrategy = OrphanRemovalStrategy.DETACH,
    relationship = {
        @Relationship(fromField = "ID", toField = "ID_ENTIDADE_A")
    }
)
private List<EntidadeB> entidadesB;
```
