# Injeção de dependências

Doc: https://developer.sankhya.com.br/docs/injecao-de-dependencias

Use **`com.google.inject.Inject`**. `javax.inject.Inject` está errado neste SDK.

```java
@Controller(serviceName = "PedidoControllerSP")
public class PedidoController {
    private final PedidoBusinessService businessService;

    @Inject
    public PedidoController(PedidoBusinessService businessService) {
        this.businessService = businessService;
    }

    @Transactional
    public void processarPedido(@Valid PedidoDTO pedido) {
        businessService.processar(pedido);
    }
}

@Component
public class PedidoBusinessService {
    private final PedidoRepository repository;

    @Inject
    public PedidoBusinessService(PedidoRepository repository) {
        this.repository = repository;
    }

    public void processar(PedidoDTO pedido) { ... }
}
```

## Estereótipos

| Anotação | Papel |
| --- | --- |
| `@Controller` | entrada HTTP (`serviceName` `*ControllerSP`). Não use o alias `@Service` em código novo. Ver [controller.md](controller.md) |
| `@Job` | agendamento |
| `@Repository` | persistência (interface) |
| `@Component` | regra, validator, helper |

Um único construtor com `@Inject`. Dependências `final`. Sem `new` de tipo gerenciado. Ciclo A↔B falha no startup (fail-fast) — quebre o ciclo.

Não misture `@Component` em classe que já tem `@Controller`.
