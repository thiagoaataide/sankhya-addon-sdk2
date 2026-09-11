# AutoDD (dicionário automático)

Doc: https://developer.sankhya.com.br/docs/autodd-gera%C3%A7%C3%A3o-autom%C3%A1tica-do-dicion%C3%A1rio-de-dados-data-dictionary

**AutoDD** gera o XML do dicionário de dados (Table / NativeTable) a partir de `@JapeEntity` **no build**. O Jape só enxerga tabela, campo, PK e relacionamento se isso estiver no dicionário — o AutoDD escreve esse XML para você.

## Não volte para XML em `datadictionary` por default

Com `autoDD = true` no `build.gradle` da raiz, **não crie** `model/src/main/resources/datadictionary/<TABELA>.xml` para mapear entidade/tabela. Isso duplica o modelo, dessincroniza Java × XML e reintroduz erro de digitação que o AutoDD elimina.

| Artefato | Onde gerar |
| --- | --- |
| Table / NativeTable (entidade `@JapeEntity`) | **Só Java** + AutoDD. Sem XML manual. |
| View, menu, dashboard, tree table, filter, tela | XML manual em `datadictionary/` — o AutoDD **não cobre**. |
| DDL `CREATE`/`ALTER` Oracle+MSSQL | **AutoDDL** (a partir do XML, automático ou manual) |

XML em `datadictionary` só para Table se `autoDD` estiver **desligado** (projeto legado). Aí use metadados.xsd / skill `data-dictionary`. Se o `build.gradle` não tiver a flag, **ligue** `autoDD = true` em vez de gerar XML.

---

## AutoDD ≠ AutoDDL (complementares)

| | AutoDD | AutoDDL |
| --- | --- | --- |
| Entrada | classes `@JapeEntity` | XML do dicionário (AutoDD **ou** XML manual) |
| Saída | XML de Table/NativeTable (pasta de **build**) | scripts DDL Oracle e MSSQL |
| O que elimina | XML manual de entidade | dbscript escrito à mão para `CREATE`/`ALTER` de tabela |
| Sozinho | Java vira dicionário; DDL ainda manual | XML vira DDL; entidade ainda precisa de XML |

Fluxo completo (as duas flags):

```groovy
addon {
    autoDD = true
    autoDDL = true
}
```

1. Anote a entidade (`@JapeEntity`, `@Id`, `@Column`, relacionamentos).
2. `./gradlew clean deployAddon`.
3. AutoDD gera o XML no build.
4. AutoDDL converte esse XML em DDL Oracle/MSSQL.
5. **Revise o DDL** antes de produção.

Não trate AutoDDL como substituto do AutoDD: um gera dicionário, o outro gera SQL.

---

## Benefícios (por que não cair no XML)

- **Agilidade** — entidade nova = Java. Sem `datadictionary/TST_MINHA_CLASSE.xml` paralelo.
- **Menos erro** — some digitação de nome de coluna/tipo diferente do POJO.
- **Java e dicionário iguais** — o modelo compilado é a fonte.
- **AutoDDL na sequência** — o XML gerado já alimenta o DDL.

O agent que “sempre cria XML na pasta datadictionary” está no padrão **pré-SDK**. Com AutoDD, isso é regressão para Table/NativeTable.

---

## Exemplos (copie o padrão)

Atributos que o AutoDD exige nas colunas: `name`, `dataType`, `description`. Relacionamento: `@JoinColumn` / `@JoinColumns` com `description` (e `dataType` na FK). Ver [orm.md](orm.md) e [foreign-keys.md](foreign-keys.md).

### 1. Entidade simples

```java
@Data
@NoArgsConstructor
@JapeEntity(entity = "TST_MinhaClasse", table = "TST_MINHA_CLASSE", description = "Minha Classe Exemplo")
public class MinhaClasse {

    @Id
    @GeneratedValue(strategy = GeneratedValue.GenerationType.AUTO)
    @Column(name = "ID", dataType = DataType.INTEGER, description = "Id")
    private Long id;

    @Column(name = "MSG", dataType = DataType.TEXT, description = "Mensagem")
    private String mensagem;

    @Column(name = "OUTRO_FIELD", dataType = DataType.INTEGER, description = "Outro Campo")
    private Long outroField;
}
```

Não gere XML `TST_MINHA_CLASSE.xml` para essa classe se `autoDD = true`.

### 2. Relacionamento (PK simples)

AutoDD lê `@JoinColumn` (PK simples) ou `@JoinColumns` (PK composta). Lista no `@Option` vira domínio no dicionário.

```java
@Data
@NoArgsConstructor
@JapeEntity(entity = "TST_MinhaClasse", table = "TST_MINHA_CLASSE", description = "Minha Classe Exemplo")
public class MinhaClasse {

    @Id
    @GeneratedValue(strategy = GeneratedValue.GenerationType.AUTO)
    @Column(name = "ID", dataType = DataType.INTEGER, description = "Id")
    private Long id;

    @Column(name = "MSG", dataType = DataType.TEXT, description = "Mensagem")
    private String mensagem;

    @OneToMany(
        cascade = Cascade.ALL,
        orphanRemovalStrategy = OrphanRemovalStrategy.DETACH
    )
    private List<MinhaOutraClasse> itens;
}

@Data
@NoArgsConstructor
@JapeEntity(entity = "TST_MinhaOutraClasse", table = "TST_MINHA_OUTRA_CLASSE", description = "Minha Outra Classe Exemplo")
public class MinhaOutraClasse {

    @Id
    @GeneratedValue(strategy = GeneratedValue.GenerationType.AUTO)
    @Column(name = "ID", dataType = DataType.INTEGER, description = "Id")
    private Long id;

    @Column(
        name = "STATUS",
        dataType = DataType.LIST,
        description = "Status",
        options = {
            @Option(label = "Ativo", value = "ATIVO"),
            @Option(label = "Inativo", value = "INATIVO")
        }
    )
    private Status status;

    @ManyToOne(cascade = Cascade.MERGE)
    @JoinColumn(
        name = "MINHA_ENTIDADE_ID",
        referencedColumnName = "ID",
        dataType = DataType.INTEGER,
        description = "Referência para MinhaClasse"
    )
    private MinhaClasse minhaClasse;
}
```

`@OneToMany` no AutoDD: sem `@JoinColumn` no pai (regra JAPE). FK no filho. Prefixo de tabela do **projeto** (`TST_`, `SGT_`, `TDC`…), nunca `AD_`.

### 3. Tabela / instância nativa

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@JapeEntity(
    entity = "TST_InstanciaCustomizadaUsuarios",
    table = "TSIUSU",
    description = "Instância Customizada de Usuários",
    isNativeTable = true,
    isNativeInstance = false
)
public class InstanciaCustomizadaUsuarios {

    @Id
    @Column(name = "CODUSU", description = "Código do Usuário", dataType = DataType.INTEGER)
    private Long codUsuario;

    @Column(name = "NOMUSU", description = "Nome do Usuário", dataType = DataType.TEXT)
    private String nomeUsuario;
}
```

- `isNativeTable = true` — tabela já existe no Om (`TSIUSU`).
- `isNativeInstance = false` — instância **do addon** sobre a tabela nativa.
- Ainda é Table/NativeTable: AutoDD gera o XML. Não copie `TSIUSU.xml` para `datadictionary`.

---

## Boas práticas

- Prefixo exclusivo de tabela/entidade (`SGT_`, `LOG_`, prefixo do addon). **Nunca `AD_`.**
- `description` e `dataType` em toda `@Column` / `@JoinColumn` — o XML gerado depende disso.
- Revise scripts AutoDDL antes de produção.
- Views, menus, dashboards, filtros, tree tables: XML em `datadictionary/`, ISO-8859-1, metadados.xsd.

## Anti-pattern

| Não | Sim (com `autoDD = true`) |
| --- | --- |
| `datadictionary/TGFVEI.xml` + `@JapeEntity` da mesma tabela | só a entidade Java |
| Ligar só `autoDDL` e escrever XML de tabela à mão | `autoDD` + `autoDDL` |
| XML de menu misturado no arquivo da Table gerada | menu/view em XML separado; Table pelo AutoDD |
