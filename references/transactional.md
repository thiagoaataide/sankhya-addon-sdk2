# Controle transacional

Doc: https://developer.sankhya.com.br/docs/controle-transacional

`@Transactional` só em método **público** de `@Controller`/`@Component`. Self-invocation (método da mesma classe) **não** abre transação.

```java
import br.com.sankhya.studio.transaction.TransactionType;

@Transactional
public void criarNovoPedido(PedidoDTO dto) {
    cabecalhoRepository.save(dto.getCabecalho());
    if (dto.getItens().isEmpty()) {
        throw new IllegalStateException("Pedido deve ter pelo menos um item.");
    }
    // rollback automático se qualquer Exception escapar
}
```

| `TransactionType` | Quando |
| --- | --- |
| `REQUIRED` (padrão) | escrita / caso geral |
| `REQUIRES_NEW` | auditoria que deve gravar mesmo se a T1 falhar |
| `NOT_SUPPORTED` | leitura pura |
| `SUPPORTS` | raro |
| `MANDATORY` / `NEVER` | contratos rígidos |

A docs mistura `Transactional.TxType.REQUIRES_NEW` e `type = TransactionType.REQUIRES_NEW`. Siga o import já usado no projeto; não misture os dois estilos no mesmo módulo.

```java
@Component
public class AuditoriaService {
    @Transactional(type = TransactionType.REQUIRES_NEW)
    public void registrarTentativa(String operacao) {
        // commit independente da transação chamadora
    }
}
```

Transações curtas. Sem I/O remoto nem loop longo dentro delas.

`@Modifying` + `@NativeQuery` **sempre** de dentro de método `@Transactional`.
