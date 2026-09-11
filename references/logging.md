# Logging e logs remotos

Docs: [Boas práticas](https://developer.sankhya.com.br/docs/boas-pr%C3%A1ticas-de-logging) · [Logs remotos](https://developer.sankhya.com.br/docs/servi%C3%A7o-de-logs-remotos)

## Bibliotecas

Só **Log4J 1.x** e **JUL** (`java.util.logging`). Não adicione Log4J2, Logback ou SLF4J extra sem checar o monolito.

Logs remotos (beta): interceptação automática para projetos com componente de logs na Área do Desenvolvedor. Sem mudança de API de logger.

## Níveis

| Nível | Uso |
| --- | --- |
| TRACE / DEBUG | só diagnóstico local |
| INFO | checkpoint esperado |
| WARN | anomalia recuperável |
| ERROR | falha de funcionalidade + stack trace |
| SEVERE / FATAL | queda / risco de corrupção |

```java
Logger logger = Logger.getLogger(MeuServico.class.getName());
try {
    executar();
} catch (Exception e) {
    logger.log(Level.SEVERE, "Erro na rotina de faturamento pedidoId=" + pedidoId, e);
    throw e;
}
```

Mensagem com contexto (id, usuário, entidade). Sem senha, token, cartão, CPF completo.

Handler de exceção: [controller-advice.md](controller-advice.md) — WARN para 4xx de negócio, SEVERE para infra.
