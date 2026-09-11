# Controller (`@Controller`)

Doc: https://developer.sankhya.com.br/docs/camada-de-controller-controller

## Use `@Controller`, não o alias `@Service`

`@Controller` é **tecnicamente equivalente** a `@Service`: as duas registram o mesmo ponto de entrada da API interna do add-on. A doc recomenda **`@Controller`** para clareza — controllers de um lado, regra de negócio em `@Component` do outro.

Em código **novo**, anote a entrada HTTP com `@Controller`. Não gere `@Service(serviceName = "...")`. `@Service` só permanece se o arquivo já existir assim; não refatore só para trocar o nome da anotação, e não misture as duas no mesmo módulo de API.

`@Service` **não** é Spring. Não importe `org.springframework.*`.

---

## Por que `@Controller`

- **Arquitetura** — o nome diz que a classe é porta de entrada, não regra.
- **Orquestração** — o método público só encadeia `@Component` (negócio), `@Repository` (persistência) e MapStruct (DTO). Sem `if` de regra, sem SQL, sem cálculo.
- **Contrato** — entrada e saída são DTOs. Nunca `@JapeEntity` no parâmetro nem no retorno (Gson serializa fields; `@Lazy` quebra). Ver [mapstruct.md](mapstruct.md).

---

## Padrão de implementação

Siga esta lista ao gerar um controller:

1. Classe `*Controller` + `@Controller(serviceName = "...ControllerSP")`.
2. Dependências `final`, um construtor `@Inject` (`com.google.inject.Inject`).
3. DTO de request (`@Valid`) e DTO de response. Sem entidade na assinatura.
4. Escrita: `@Transactional` no método (ou `transactionType = Required` na classe).
5. Negócio em `@Component` (`*Business`). Persistência em `@Repository`. Conversão no mapper.
6. JavaDoc na classe e nos métodos públicos (viram ações da API).
7. Erro: deixe subir; [controller-advice.md](controller-advice.md) serializa. Sem `try/catch` de negócio.
8. Teste o controller com mock das dependências — sem banco.

Exemplo canônico (doc oficial, com `serviceName` obrigatório):

```java
@Controller(serviceName = "EstoqueControllerSP")
public class EstoqueController {

    private final EstoqueRepository estoqueRepository;
    private final EstoqueBusiness estoqueBusiness;
    private final EstoqueMapper estoqueMapper;

    @Inject
    public EstoqueController(
            EstoqueRepository estoqueRepository,
            EstoqueBusiness estoqueBusiness,
            EstoqueMapper estoqueMapper
    ) {
        this.estoqueRepository = estoqueRepository;
        this.estoqueBusiness = estoqueBusiness;
        this.estoqueMapper = estoqueMapper;
    }

    /**
     * Aplica a atualização de estoque e persiste o resultado.
     */
    @Transactional
    public EstoqueDTO atualizarEstoque(@Valid AtualizarEstoqueRequestDTO requestDTO) {
        Estoque estoque = estoqueBusiness.processarAtualizacao(requestDTO);
        Estoque estoqueSalvo = estoqueRepository.save(estoque);
        return estoqueMapper.toDTO(estoqueSalvo);
    }

    /**
     * Lista estoques do produto. Sem transação de escrita.
     */
    public List<EstoqueDTO> listarPorProduto(BigDecimal codProduto) {
        List<Estoque> estoques = estoqueRepository.findByProduto(codProduto);
        return estoques.stream()
                .map(estoqueMapper::toDTO)
                .collect(Collectors.toList());
    }
}
```

O `save` depois do `@Component` é orquestração, não regra. A regra fica em `estoqueBusiness.processarAtualizacao`.

---

## Como funciona

- `serviceName` é **obrigatório**. Convenção: termina em `SP` (`PedidoControllerSP`, não `PedidoController` nem `PedidoServiceSP`).
- Todo método **público** vira ação: `serviceName.nomeDoMetodo`.
- Injeção só no construtor.

### URL

```
<dns>/<contexto-modulo>/service.sbr?serviceName=<serviceName>.<nomeDoMetodo>
```

`contexto-modulo` = `rootProject.name` do `settings.gradle`.

```
http://localhost:8080/addon-template/service.sbr?serviceName=PedidoControllerSP.criarPedido&mgeSession=<jsession-id>
```

### Autenticação

Sem Gateway: `MobileLoginSP.login` devolve `jsessionId`; passe em `mgeSession`. Com Gateway, o login mobile **não** é necessário.

```bash
curl --location 'http://localhost:8080/mge/service.sbr?serviceName=MobileLoginSP.login&outputType=json' \
--header 'Content-Type: application/json' \
--data '{
    "requestBody": {
        "NOMUSU": {"$": "USUARIO"},
        "INTERNO": {"$": "SENHA_DO_USUARIO"}
    }
}'
```

---

## `transactionType` na classe

Padrão de **todos** os métodos, até um `@Transactional` no método sobrepor. Detalhes de tipos: [transactional.md](transactional.md).

```java
@Controller(
    serviceName = "RelatorioControllerSP",
    transactionType = TransactionType.NotSupported
)
public class RelatorioController {
    // leituras: sem transação
}
```

| `TransactionType` | Efeito | Quando |
| --- | --- | --- |
| `Required` | sempre em transação (reusa ou cria) | escrita / CRUD |
| `NotSupported` | fora de transação (suspende se houver) | leitura que não precisa de consistência |
| `Supported` (**padrão**) | usa transação se já existir; senão segue sem | leitura que pode entrar numa transação maior |

Sobreposição no método:

```java
@Controller(serviceName = "ConsultaControllerSP", transactionType = TransactionType.NotSupported)
public class ConsultaController {

    public List<ProdutoDTO> listarProdutos() {
        // NotSupported da classe
    }

    @Transactional(type = TransactionType.RequiresNew)
    public void registrarLogDeConsulta() {
        // transação própria
    }
}
```

A doc do controller usa `NotSupported` / `RequiresNew`. O módulo de transação às vezes aparece como `NOT_SUPPORTED`. Siga o import do projeto; não misture os dois estilos no mesmo tipo.

---

## Envelope JSON (API legada Sankhya)

O parâmetro Java vira **chave** em `requestBody` (nome do argumento, não o tipo).

```java
public PedidoCriadoDTO criarPedido(PedidoDTO pedido) { /* ... */ }
```

Request:

```json
{
  "serviceName": "PedidoControllerSP.criarPedido",
  "requestBody": {
    "pedido": {
      "cliente": { "codigo": 12345, "nome": "João Silva" },
      "itens": [
        { "produtoId": 100, "quantidade": 2, "valorUnitario": 150.50 },
        { "produtoId": 101, "quantidade": 1, "valorUnitario": 250.00 }
      ],
      "observacao": "Entrega urgente"
    }
  }
}
```

POST `.../service.sbr?serviceName=PedidoControllerSP.criarPedido` com `Content-Type: application/json`.

Sucesso (`status` `"1"`):

```json
{
  "serviceName": "PedidoControllerSP.criarPedido",
  "status": "1",
  "pendingPrinting": "false",
  "transactionId": "CB0F625A72C214CF8449F0B18E1FA81A",
  "responseBody": {
    "numeroPedido": 987654,
    "dataVencimento": "2024-12-31",
    "valorTotal": 551.00,
    "status": "PENDENTE"
  }
}
```

Erro: `status` `"0"` (execução), `"3"` (timeout), `"4"` (cancelado por concorrência). Sem `responseBody`; mensagem em `statusMessage`. Com `@ControllerAdvice`, o corpo de erro pode ser o DTO do handler.

```json
{
  "serviceName": "PedidoControllerSP.criarPedido",
  "status": "0",
  "pendingPrinting": "false",
  "transactionId": "CB0F625A72C214CF8449F0B18E1FA81A",
  "statusMessage": "Erro de validação: O campo nome é obrigatório;\n\t- O campo descricao é obrigatório"
}
```

---

## Boas práticas

- Só orquestrar. Regra e validação de negócio → `@Component`.
- Sempre DTO na fronteira. Bean Validation no DTO de entrada (`@Valid`).
- Nome da ação = verbo + substantivo (`criarPedido`, `atualizarEstoque`), não `execute` / `process`.
- Um controller por agregado / caso de uso, não um “Deus” `AddonControllerSP`.

## Anti-pattern

| Não | Sim |
| --- | --- |
| `@Service(serviceName = "PedidoServiceSP")` em código novo | `@Controller(serviceName = "PedidoControllerSP")` |
| `serviceName` sem `SP` | `...ControllerSP` |
| retornar `@JapeEntity` | DTO + MapStruct |
| regra / SQL / `if` de negócio no método | `@Component` + orquestração |
| `try/catch` para engolir ou relançar à toa | `@ControllerAdvice` |
| `@Component` na mesma classe que já é `@Controller` | um estereótipo só |
| `javax.inject.Inject` | `com.google.inject.Inject` no construtor |
