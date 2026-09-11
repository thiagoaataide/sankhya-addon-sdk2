# `@ControllerAdvice`

Doc: https://developer.sankhya.com.br/docs/11_controller_advice

Um ponto só para erros de `@Controller`. Rollback automático da transação ativa.

```java
@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger logger = Logger.getLogger(GlobalExceptionHandler.class.getName());

    @ExceptionHandler({ObjectNotFoundException.class})
    public ErrorResponse handleObjectNotFound(ObjectNotFoundException e) {
        logger.log(Level.WARNING, "Recurso não encontrado", e);
        return new ErrorResponse("RESOURCE_NOT_FOUND", "O recurso solicitado não foi encontrado.");
    }

    @ExceptionHandler({ValidationException.class})
    public ErrorResponse handleValidation(ValidationException e) {
        logger.log(Level.WARNING, "Erro de validação", e);
        return new ErrorResponse("VALIDATION_ERROR", e.getMessage());
    }
}
```

Regras:

- Handler **não pode** retornar `void`.
- Não capture `Exception.class` genérico a menos que o projeto já tenha essa política — prefira tipos específicos.
- Não faça `try/catch` no controller para depois relançar.
- Objeto retornado vira JSON (Gson).

Logging: [logging.md](logging.md).
