# Bean Validation

Doc: https://developer.sankhya.com.br/docs/bean-validation

JSR 303/380. Ativa só com `@Valid` no parâmetro do `@Controller`. Falha → SDK lança **antes** da lógica. Valide no **DTO de entrada**. Sempre passe `message` em português, específica do campo. Combine anotações no mesmo campo.

```java
@Transactional
public void cadastrarUsuario(@Valid UsuarioDTO usuario) {
    businessService.salvar(usuario);
}
```

Pacote padrão: `javax.validation.constraints.*`. `@Length` vem do Hibernate Validator (`org.hibernate.validator.constraints.Length`).

---

## Nulidade e conteúdo

| Anotação | Alvo | Regra |
| --- | --- | --- |
| `@NotNull` | qualquer tipo | não `null` |
| `@Null` | qualquer tipo | **deve** ser `null` (útil com groups de create vs update) |
| `@NotBlank` | `String` | não `null`, não `""`, não só espaços |
| `@NotEmpty` | coleção, mapa, array, `String` | não `null` e com pelo menos um elemento |

```java
@NotNull(message = "O ID do usuário é obrigatório.")
private Long id;

@NotBlank(message = "O nome do usuário é obrigatório.")
private String nome;

@NotEmpty(message = "O pedido deve ter pelo menos um item.")
private List<ItemDTO> itens;

@Null(groups = CreateGroup.class)
@NotNull(groups = UpdateGroup.class)
private Long id;
```

## Tamanho

| Anotação | Alvo | Regra |
| --- | --- | --- |
| `@Size(min, max)` | `String`, Collection, Array, Map | intervalo de tamanho |
| `@Length(min, max)` | `String` (Hibernate Validator) | intervalo de caracteres |

```java
@Size(min = 2, max = 50, message = "Nome deve ter entre 2 e 50 caracteres")
private String nome;

@Size(max = 5, message = "Máximo 5 endereços permitidos")
private List<EnderecoDTO> enderecos;

@Length(min = 10, max = 500, message = "Descrição deve ter entre 10 e 500 caracteres")
private String descricao;
```

## Numéricas

| Anotação | Regra |
| --- | --- |
| `@Min(value)` / `@Max(value)` | inteiro ≥ / ≤ limite |
| `@DecimalMin(value)` / `@DecimalMax(value)` | decimal; `inclusive = false` exclui o limite |
| `@Positive` / `@PositiveOrZero` | `> 0` / `≥ 0` |
| `@Negative` / `@NegativeOrZero` | `< 0` / `≤ 0` |
| `@Digits(integer, fraction)` | teto de dígitos inteiros e fracionários |

```java
@Min(value = 1, message = "A quantidade mínima é 1.")
@Max(value = 9999, message = "Quantidade máxima é 9999")
private Integer quantidade;

@DecimalMin(value = "0.01", message = "Valor mínimo é 0.01")
@DecimalMax(value = "999999.99", inclusive = false, message = "Valor deve ser menor que 999999.99")
private BigDecimal limite;

@Positive(message = "O valor do produto deve ser positivo.")
private BigDecimal preco;

@PositiveOrZero(message = "Saldo não pode ser negativo")
private BigDecimal saldo;

@NegativeOrZero(message = "Débito deve ser negativo ou zero")
private BigDecimal debito;

@Digits(integer = 10, fraction = 2, message = "Formato: máximo 10 dígitos inteiros e 2 decimais")
private BigDecimal valor;
```

Para `BigDecimal` de dinheiro, prefira `@DecimalMin` / `@DecimalMax` / `@Digits` em vez de `@Min`/`@Max`.

## Formato

| Anotação | Regra |
| --- | --- |
| `@Email` | formato de e-mail |
| `@Pattern(regexp)` | regex Java |

```java
@Email(message = "Email deve ter um formato válido")
@NotBlank(message = "Email é obrigatório")
@Size(max = 100, message = "Email deve ter no máximo 100 caracteres")
private String email;

@Pattern(regexp = "[A-Z]{2}[0-9]{4}", message = "A placa deve seguir o formato AA1234.")
private String placa;

@Pattern(regexp = "\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}", message = "CPF deve seguir o formato: 000.000.000-00")
private String cpf;

@Pattern(regexp = "\\(\\d{2}\\)\\s\\d{4,5}-\\d{4}", message = "Telefone deve seguir o formato: (11) 99999-9999")
private String telefone;

@Pattern(regexp = "\\d{5}-?\\d{3}", message = "CEP deve ter o formato: 00000-000")
private String cep;
```

Anotações customizadas da doc (`@ValidCPF`) **não** fazem parte do JSR. Só use se o projeto já tiver o constraint; senão, `@Pattern` ou constraint própria.

## Data e hora

| Anotação | Regra |
| --- | --- |
| `@Past` | estritamente no passado |
| `@PastOrPresent` | passado ou agora |
| `@Future` | estritamente no futuro |
| `@FutureOrPresent` | futuro ou agora |

Tipos: `Date`, `Calendar`, `LocalDate`, `LocalDateTime`, `Instant`, etc.

```java
@Past(message = "Data de nascimento deve estar no passado")
private LocalDate dataNascimento;

@PastOrPresent(message = "Data de cadastro deve ser hoje ou no passado")
private LocalDateTime dataCadastro;

@Future(message = "Data do evento deve estar no futuro")
private LocalDateTime dataEvento;

@FutureOrPresent(message = "Data de entrega deve ser hoje ou no futuro")
private LocalDate dataEntrega;
```

## Booleanas

| Anotação | Regra |
| --- | --- |
| `@AssertTrue` | valor deve ser `true` |
| `@AssertFalse` | valor deve ser `false` |

```java
@AssertTrue(message = "Deve aceitar os termos de uso")
private Boolean aceitaTermos;

@AssertFalse(message = "Não deve estar suspenso")
private Boolean suspenso;
```

Útil em flags de aceite. Não substitua regra de negócio complexa no `@Component`.

## Cascata (`@Valid` no campo)

```java
public class PedidoDTO {
    @NotNull
    private Long idCliente;

    @Valid
    @NotEmpty
    @Size(max = 50, message = "Máximo 50 itens por pedido")
    private List<ItemDTO> itens;

    @Valid
    @NotNull(message = "Endereço é obrigatório")
    private EnderecoDTO endereco;
}

public class ItemDTO {
    @NotNull
    private Long idProduto;

    @Positive(message = "A quantidade deve ser positiva.")
    private int quantidade;
}
```

Sem `@Valid` no campo aninhado, as anotações do filho **não** rodam.

## Groups

```java
@NotNull(groups = UpdateGroup.class)
@Null(groups = CreateGroup.class)
private Long id;
```

Só use groups se o mesmo DTO servir create e update. Caso contrário, DTOs separados (`CriarPedidoRequest` / `AtualizarPedidoRequest`).

## Tratamento de erro

Não faça `try/catch` de `ConstraintViolationException` no controller. Deixe [controller-advice.md](controller-advice.md) serializar a resposta.

Se precisar inspecionar violações num `@Component`:

```java
e.getConstraintViolations().forEach(violation -> {
    String campo = violation.getPropertyPath().toString();
    String mensagem = violation.getMessage();
    Object valorInvalido = violation.getInvalidValue();
});
```

## Catálogo rápido

`@AssertFalse` · `@AssertTrue` · `@DecimalMax` · `@DecimalMin` · `@Digits` · `@Email` · `@Future` · `@FutureOrPresent` · `@Length` · `@Max` · `@Min` · `@Negative` · `@NegativeOrZero` · `@NotBlank` · `@NotEmpty` · `@NotNull` · `@Null` · `@Past` · `@PastOrPresent` · `@Pattern` · `@Positive` · `@PositiveOrZero` · `@Size` · `@Valid`
