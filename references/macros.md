# MacroTranslator

Doc: https://developer.sankhya.com.br/docs/macrotranslator-documenta%C3%A7%C3%A3o-de-macros-sankhya

Use macros em `@Criteria`, `@NativeQuery` e dbscripts. **Não** escreva `SYSDATE` / `GETDATE` / `NVL` / `ISNULL` direto.

| Macro | Propósito | Exemplo |
| --- | --- | --- |
| `dbDate()` | agora no banco | `this.DTNEG <= dbDate()` |
| `nullValue(expr, default)` | NVL/ISNULL | `nullValue(SALARIO, 0)` |
| `ignorecase(expr)` | compara sem acento/caixa | `ignorecase(NOME) = ignorecase(:nome)` |
| `normalizeText(expr)` | tira acento | `normalizeText(NOME) LIKE :q` |
| `maxLines(n)` | limite de linhas | `SELECT maxLines(10) * FROM ...` |
| `concatstr(a, b, ...)` | concat portável | `concatstr(NOME, ' ', SOBRENOME)` |
| `onlydate(ts)` | zera hora | `onlydate(this.DTNEG) = onlydate(:dia)` |
| `diffdays(d1, d2)` | diferença em dias | `diffdays(DTFIM, DTINI)` |
| `convertToVarchar(expr)` | para texto | `convertToVarchar(CODPARC)` |
| `convertToNumber(expr)` | para número | `convertToNumber(CODIGO)` |
| `yearMonth(campo)` | YYYYMM | `yearMonth(DTNEG) = :anoMes` |
| `addMonths(data, n)` | soma meses | `addMonths(dbDate(), -1)` |
| `sqldatabase.TABELA` | nome qualificado | `SELECT * FROM sqldatabase.TGFPAR` |
| `${user.name}` | schema/usuário | `SELECT * FROM ${user.name}TGFPAR` |

```java
@Criteria(clause = "ignorecase(this.NOMEPARC) = ignorecase(:nome) AND this.DTNEG <= dbDate()")
List<Parceiro> findByNomeAteHoje(@Parameter(name = "nome") String nome);

@NativeQuery("SELECT maxLines(50) CODPARC, NOMEPARC FROM TGFPAR WHERE ATIVO = 'S' AND nullValue(CODVEND, 0) = :vend")
List<ParceiroResumo> topAtivos(@Parameter(name = "vend") BigDecimal vend);
```

Lista completa (trunc*, leftPad, subString, convertToTimestamp, …): documentação oficial acima. Não invente macro.
