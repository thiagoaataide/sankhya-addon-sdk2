# Repositório (`@Repository`)

Doc: https://developer.sankhya.com.br/docs/repositorio-dados

Interface apenas. O SDK gera a implementação. Sem `JapeFactory.dao`, sem concatenar SQL, sem query methods Spring (`findByPlacaStartingWith` **não existe**).

```java
import br.com.sankhya.sdk.data.repository.JapeRepository;
import br.com.sankhya.studio.stereotypes.Repository;

@Repository
public interface VeiculoRepository extends JapeRepository<Long, Veiculo> {
    @Criteria(clause = "this.PLACA = :placa")
    Optional<Veiculo> findByPlaca(@Parameter(name = "placa") String placa);
}
```

Genéricos: **`JapeRepository<ID, Entity>`** (ID primeiro). A doc oficial às vezes inverte os parâmetros; siga o que já compila no projeto.

PK de tabela nativa Sankhya costuma ser `BigDecimal`. PK de tabela do addon costuma ser `Integer`/`Long`. PK composta: `JapeRepository<ItemNotaPK, ItemNota>` (confira a ordem no jar do projeto).

Macros em qualquer clause/SQL: [macros.md](macros.md).

---

## CRUD herdado

| Método | Retorno (doc oficial) | Uso |
| --- | --- | --- |
| `save(T entity)` | `T` | insert ou update |
| `findByPK(ID id)` | `Optional<T>` na doc; o jar 2.0 pode devolver `T` nullable | um registro pela PK |
| `findAll()` | `List<T>` | todos (teto da sessão, ~500) |
| `findAll(Pageable pageable)` | `Page<T>` | página + sort |
| `delete(T entity)` | `void` | remove |

Métodos herdados podem lançar `Exception` checada. Espelhe a assinatura que o projeto já usa (`Optional` vs null-check).

```java
Veiculo encontrado = repository.findByPK(id);
if (encontrado == null) {
    throw new IllegalStateException("Veículo não encontrado: " + id);
}
```

Se o projeto tratar como Optional:

```java
Veiculo veiculo = repository.findByPK(id)
    .orElseThrow(() -> new IllegalStateException("Veículo não encontrado: " + id));
```

---

## Tipos de retorno (consultas customizadas)

Válidos em `@Criteria` e `@NativeQuery`, salvo as notas.

| Retorno | Quando | Nota |
| --- | --- | --- |
| `T` | um registro | pode ser `null`; prefira `Optional<T>` |
| `Optional<T>` | 0 ou 1 entidade | preferido para busca única |
| `List<T>` | N entidades | teto ~500 sem paginação |
| `Page<T>` | página | **só `@Criteria`** + `Pageable` |
| `String`, `Long`, `Integer`, `BigDecimal`, `Boolean`… | 1 coluna escalar | **só `@NativeQuery`**; mais de 1 coluna → `ResultHasMoreThanOneColumnException` |
| `List<Long>` (ou outro escalar) | lista de 1 coluna | `@NativeQuery` |
| Interface `@NativeQuery.Result` | várias colunas / projeção | getters = alias da query |
| `List<MeuDTO>` | N projeções | `@NativeQuery` |
| `int` / `Integer` / `void` | DML | `@Modifying` + `@NativeQuery` |

Paginação **não** existe em `@NativeQuery`. Listagem grande nativa: `maxLines()` ou LIMIT/TOP via XML por banco.

---

## `@Criteria` — WHERE JAPE

SELECT na entidade do repositório. Clause = condição (não escreva `SELECT`).

```java
@Criteria(clause = "CAMPO = :parametro")
ReturnType nomeDoMetodo(TipoParametro parametro);
```

```java
@Repository
public interface VeiculoRepository extends JapeRepository<Long, Veiculo> {

    @Criteria(clause = "this.PLACA = :placa")
    Optional<Veiculo> findByPlaca(@Parameter(name = "placa") String placa);

    @Criteria(clause = "this.ATIVO = :ativo")
    List<Veiculo> findByAtivo(@Parameter(name = "ativo") Boolean ativo);

    @Criteria(clause = "this.CODEMP = :empresa AND this.STATUS = :status")
    List<Pedido> findByEmpresaAndStatus(
        @Parameter(name = "empresa") Long empresa,
        @Parameter(name = "status") String status
    );

    @Criteria(clause = "this.DESCRPROD LIKE :termo")
    List<Produto> findByDescricaoContaining(@Parameter(name = "termo") String termo);

    @Criteria(clause = "this.CODPROD IN (:codigos)")
    List<Produto> findByCodigos(@Parameter(name = "codigos") List<Long> codigos);

    @Criteria(clause = "this.DTNEG BETWEEN :dataInicio AND :dataFim")
    List<Pedido> findByPeriodo(
        @Parameter(name = "dataInicio") LocalDate inicio,
        @Parameter(name = "dataFim") LocalDate fim
    );

    @Criteria(clause = "this.DTMOV = dbDate()")
    List<Movimentacao> findByDataAtual();
}
```

- Prefixe colunas com `this.`.
- `@Parameter(name = "x")` quando o nome Java ≠ `:x`. Forma posicional `@Parameter("x")` pode falhar no compile.
- Sem query methods: o nome do método é só documentação (`findByPlaca` **não** gera SQL).

---

## `@NativeQuery` — SQL nativo

Use quando `@Criteria` não chega: JOIN, subquery, agregação, relatório, DTO, DML em massa.

```java
@NativeQuery("SELECT CAMPO1, CAMPO2 FROM MINHA_TABELA WHERE CAMPO = :parametro")
List<MeuDTO> nomeDoMetodo(@Parameter(name = "parametro") TipoParametro parametro);
```

### Projeção (várias colunas) — `@NativeQuery.Result`

Getters devem casar **exatamente** com coluna ou alias. Divergência → campo `null`, sem erro de compile.

```java
@NativeQuery.Result
public interface ResumoProdutoDTO {
    Long getCodigo();
    String getDescricao();
    BigDecimal getPreco();
}

@NativeQuery("SELECT CODPROD AS Codigo, DESCRPROD AS Descricao, VLRVENDA AS Preco FROM TGFPRO WHERE ATIVO = 'S'")
List<ResumoProdutoDTO> listarProdutosAtivos();
```

`SELECT *` é anti-pattern. Alias explícito.

### Escalar (uma coluna)

```java
@NativeQuery("SELECT DESCRPROD FROM TGFPRO WHERE CODPROD = :codigo")
String buscarDescricaoPorCodigo(@Parameter(name = "codigo") Long codigo);

@NativeQuery("SELECT CODPROD FROM TGFPRO WHERE ATIVO = 'S'")
List<Long> listarCodigosDeProdutosAtivos();

@NativeQuery("SELECT COUNT(1) FROM TGFPRO")
Long contarTotalDeProdutos();
```

Válido: `SELECT NOME FROM TGFPAR`.  
Inválido: `SELECT CODPARC, NOME FROM TGFPAR` como `String` → `ResultHasMoreThanOneColumnException`.

Ambiguidade `ResultSet` (`getString` vs `getNString`) só em escalar:

```java
@NativeQuery(value = "SELECT CAMPO_NVARCHAR FROM MINHA_TABELA", method = ResultSetMethods.GET_N_STRING)
String buscarComNString();
```

DTO resolve pelo tipo do getter; `method` não se aplica.

### `JdbcWrapper` (listener / transação já aberta)

```java
@NativeQuery("SELECT COUNT(1) FROM TGFCAB WHERE STATUS = 'P'")
Long contarPendentes(JdbcWrapper jdbc);

JdbcWrapper jdbc = event.getJdbcWrapper();
Long pendentes = repository.contarPendentes(jdbc);
```

---

## `@Modifying` + `@NativeQuery`

UPDATE / INSERT / DELETE em massa. `@Delete` **foi descontinuado**.

Retorno: `int` / `Integer` (linhas afetadas) ou `void`. **Sempre** dentro de `@Transactional`.

```java
@Modifying
@NativeQuery("UPDATE TGFPRO SET ATIVO = 'N' WHERE CODGRUPOPROD = :grupo")
int desativarProdutosPorGrupo(@Parameter(name = "grupo") Long grupo);

@Modifying
@NativeQuery("UPDATE TGFPRO SET VLRVENDA = VLRVENDA * :fator WHERE CODGRUPOPROD = :grupo")
int reajustarPrecoPorGrupo(
    @Parameter(name = "fator") BigDecimal fator,
    @Parameter(name = "grupo") Long grupo
);

@Modifying
@NativeQuery("DELETE FROM AD_LOGS WHERE DTEXPIRACAO < :data")
int excluirLogsExpirados(@Parameter(name = "data") LocalDate data);
```

```java
@Component
public class ProdutoService {
    @Transactional
    public void aplicarReajuste(Long grupo, BigDecimal fator) {
        repository.reajustarPrecoPorGrupo(fator, grupo);
    }
}
```

---

## SQL em arquivo (`fromFile = true`)

Query longa, reuso, ou SQL diferente Oracle vs MSSQL.

```java
@NativeQuery(value = "queries/listar-veiculos-ativos.sql", fromFile = true)
List<VeiculoView> listarAtivos(@Parameter(name = "ativo") String ativo);
```

Arquivo: `model/src/main/resources/queries/listar-veiculos-ativos.sql`

```sql
SELECT v.CODVEI, v.PLACA, v.DESCRICAO
FROM TGFVEI v
WHERE v.ATIVO = :ativo
ORDER BY v.DESCRICAO
```

XML multi-banco (`<both>` vence `<oracle>` / `<mssql>`):

```xml
<sql>
    <both>
        SELECT CAB.NUNOTA, PAR.NOMEPARC
        FROM TGFCAB CAB
        JOIN TGFPAR PAR ON CAB.CODPARC = PAR.CODPARC
        WHERE CAB.DTNEG BETWEEN :dataInicio AND :dataFim
    </both>
</sql>
```

Quando a sintaxe diverge, **não** use `<both>`:

```xml
<sql>
    <oracle>SELECT NVL(SUM(ITE.QTDNEG), 0) AS TOTAL FROM TGFITE ITE WHERE ITE.CODPROD = :codProd</oracle>
    <mssql>SELECT ISNULL(SUM(ITE.QTDNEG), 0) AS TOTAL FROM TGFITE ITE WHERE ITE.CODPROD = :codProd</mssql>
</sql>
```

Preferir macros (`nullValue`) a NVL/ISNULL quando der. Compile-time: arquivo existe, XML válido, parâmetros iguais nos dois bancos. Runtime: `InvalidQueryFileException`. Cache na primeira leitura.

---

## Paginação (`@Criteria` apenas)

```java
@Criteria(clause = "this.ATIVO = :ativo")
Page<Veiculo> findByAtivoPaginado(
    @Parameter(name = "ativo") Boolean ativo,
    Pageable pageable
);
```

```java
PageRequest pageRequest = PageRequest.of(0, 10, Sort.by("PLACA", Direction.DESC));
return repository.findByAtivoPaginado(ativo, pageRequest);
```

`page` começa em 0; `size` ≥ 1. Sem `sort`, ordena por ID crescente.

Sessão JAPE corta `List` em ~500. Listagem potencialmente maior → `Page` + `@Criteria`, não `findAll()`.

---

## `ParamMatrix` (IN de várias colunas)

Sintaxe Oracle ≠ MSSQL. Com `@NativeQuery`, use XML por banco. Com `@Criteria`, **dois métodos** + `SqlHelper.isOracle()`.

```java
ParamMatrix matrix = ParamMatrix.of(
    Arrays.asList(1L, "Descrição A"),
    Arrays.asList(2L, "Descrição B")
);
```

Prefira XML nativo para não ramificar o service.

---

## Esclarecimentos (o que costuma quebrar)

1. **Nome do método não gera query.** Sem `@Criteria`/`@NativeQuery`, não há SELECT.
2. **`@NativeQuery` não pagina.** `Pageable` só com `@Criteria`.
3. **Escalar = 1 coluna.** Várias colunas → DTO `@NativeQuery.Result`.
4. **Alias do getter.** `getCodigo()` casa com `AS Codigo` (ou `CODIGO`, conforme o driver). Teste se vier `null`.
5. **Teto 500** em `List` sem página.
6. **`@Modifying` sem `@Transactional`** deixa o banco inconsistente.
7. **Repositório não tem regra de negócio** (`default aprovarPedido` é anti-pattern).
8. **`IN (:lista)` vazia:** valide no `@Component` e retorne lista vazia.
9. **Palavra reservada** como nome de coluna (`TIMESTAMP`, `DECIMAL`) quebra o SQL.
10. **`@Delete` morto.** Só `@Modifying` + `@NativeQuery`.
11. Validar parâmetro no **service** (`placa` vazia), não no repositório.

---

## Anti-patterns

| Não | Sim |
| --- | --- |
| `findByPlacaStartingWith` sem anotação | `@Criteria(clause = "this.PLACA LIKE :prefix")` |
| `@Criteria(clause = "1 = 1")` | filtro obrigatório (`ATIVO`, `CODEMP`) |
| `@Modifying` fora de transação | `@Transactional` no `@Component` |
| lógica no `default` da interface | `@Component` + `save` |
| `Produto findByCodigo(...)` cru | `Optional<Produto>` |
| `SELECT *` | colunas + alias |
| concatenar `"PLACA = '" + placa + "'"` | `:placa` |

---

## Exemplo completo

```java
@NativeQuery.Result
public interface PedidoResumoDTO {
    Long getNumero();
    BigDecimal getValor();
}

@Repository
public interface PedidoRepository extends JapeRepository<Long, Pedido> {

    @Criteria(clause = "this.CODPARC = :codigoCliente")
    List<Pedido> findByCliente(@Parameter(name = "codigoCliente") Long codigoCliente);

    @NativeQuery("SELECT NUNOTA AS numero, VLRNOTA AS valor FROM TGFCAB WHERE STATUS = :status AND CODEMP = :empresa")
    List<PedidoResumoDTO> findResumoPorStatus(
        @Parameter(name = "status") String status,
        @Parameter(name = "empresa") Long empresa
    );

    @Modifying
    @NativeQuery("DELETE FROM TGFCAB WHERE STATUS = 'R' AND DHALTER < :dataLimite")
    int deleteRascunhosAntigos(@Parameter(name = "dataLimite") LocalDateTime dataLimite);
}

@Component
public class PedidoService {
    private final PedidoRepository pedidoRepository;

    @Inject
    public PedidoService(PedidoRepository pedidoRepository) {
        this.pedidoRepository = pedidoRepository;
    }

    @Transactional
    public void limparRascunhosAntigos() {
        pedidoRepository.deleteRascunhosAntigos(LocalDateTime.now().minusDays(30));
    }

    public List<Pedido> buscarPedidosDoCliente(Long codigoCliente) {
        if (codigoCliente == null) {
            throw new IllegalArgumentException("Código do cliente é obrigatório.");
        }
        return pedidoRepository.findByCliente(codigoCliente);
    }
}
```
