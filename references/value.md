# `@Value` — injeção de valores

Doc: https://developer.sankhya.com.br/docs/inje%C3%A7%C3%A3o-de-valores-value

Não use `MGECoreParameter.getParameter`, `System.getenv` nem `Integer.parseInt` de config no método. Injete no campo de um `@Component` / `@Controller`. Campo **não** pode ser `final`. Classe **não** pode ser criada com `new`.

`type` e `defaultValue` são **obrigatórios**. Informe `value` **ou** `param` (se os dois existirem, `param` vence).

```java
@Value(
    value = "PROPERTY_NAME",
    param = "PROPERTY_NAME",
    group = "GROUP_NAME",
    type = ValueType.ENV_VAR,
    defaultValue = "default"
)
```

| Atributo | Obrigatório | Uso |
| --- | --- | --- |
| `value` | um dos dois | nome da propriedade (`ENV_VAR`, `SYSTEM_PROPERTY`) |
| `param` | um dos dois | nome do parâmetro Sankhya (vence `value`) |
| `group` | não | só com `SANKHYA_PARAM` |
| `type` | sim | fonte |
| `defaultValue` | sim | fallback (string; SDK converte) |

---

## Tipos de injeção (eager vs lazy)

São **dois** modos, definidos pelo tipo do **campo**, não pelo `ValueType`.

| | Eager (direta) | Lazy com cache (**recomendado** para opcional) |
| --- | --- | --- |
| Campo | `private Integer serverPort` | `private Provider<Integer> maxConnections` |
| Quando resolve | construção do objeto | primeira chamada a `.get()` |
| Cache | já resolvido | sim, depois do primeiro `get()` |
| Use quando | config sempre necessária na subida | feature flag, URL, parâmetro que pode nem ser lido |

### Eager — valor na construção

```java
@Component
public class DatabaseConfig {

    @Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
    private Integer serverPort;

    @Value(value = "debug.enabled", type = ValueType.SYSTEM_PROPERTY, defaultValue = "false")
    private Boolean debugEnabled;

    @Value(value = "app.name", type = ValueType.ENV_VAR, defaultValue = "MyApp")
    private String appName;

    public void initialize() {
        // já convertidos; sem .get()
        int porta = serverPort;
        boolean debug = debugEnabled;
    }
}
```

### Lazy — `Provider<T>` + `.get()`

```java
@Component
public class ServiceConfig {

    @Value(value = "DATABASE_URL", type = ValueType.ENV_VAR, defaultValue = "jdbc:h2:mem:test")
    private Provider<String> databaseUrl;

    @Value(param = "MAX_CONNECTIONS", type = ValueType.SANKHYA_PARAM, defaultValue = "10")
    private Provider<Integer> maxConnections;

    @Value(param = "FEATURE_FLAG", type = ValueType.SANKHYA_PARAM, defaultValue = "false")
    private Provider<Boolean> featureFlag;

    public void conectar() {
        if (featureFlag.get()) {
            String url = databaseUrl.get();
            int max = maxConnections.get();
            conectar(url, max);
        }
        // se a flag for false, URL e pool nem são resolvidos
    }
}
```

Na geração de código: parâmetro do Om e feature flag → `Provider<T>`. Porta, ambiente, nome do app que o construtor já usa → campo direto.

### Cache do `Provider` (lazy)

O valor é resolvido **uma vez por instância**, na primeira `.get()`, e reutilizado. Thread-safe (double-checked locking). **Não** acompanha mudança de parâmetro Om, env ou `-D` depois disso.

```java
String url1 = databaseUrl.get(); // resolução + grava cache (pode ser custoso)
String url2 = databaseUrl.get(); // cache
String url3 = databaseUrl.get(); // cache
```

Não gere código que chame `.get()` esperando reler `MGECoreParameter` a cada request.

Teste (forçar nova resolução):

```java
ValueProvider<String> provider = (ValueProvider<String>) databaseUrl;
provider.clearCache();
```

Eager não tem cache separado: o campo já nasceu resolvido.

| | Eager | Lazy (`Provider`) |
| --- | --- | --- |
| Resolução | criação do objeto | primeiro `get()` |
| Cache | N/A | sim, após o primeiro `get()` |
| Muda em runtime | não | não (até `clearCache` no teste) |

---

## Fontes de propriedades (`ValueType`)

Quatro fontes. O agent copia o `type` + atributo (`value` vs `param`) do snippet correspondente. Não misture: `ENV_VAR` não usa `param`; `SANKHYA_PARAM` não usa `value` (use `param`).

### 1. `ENV_VAR` — variável de ambiente

`value` = nome da variável do SO / `.env` do Addon Studio.

```java
@Value(value = "DATABASE_URL", type = ValueType.ENV_VAR, defaultValue = "jdbc:h2:mem:test")
private Provider<String> databaseUrl;

@Value(value = "API_KEY", type = ValueType.ENV_VAR, defaultValue = "")
private String apiKey;
```

Como definir a fonte:

```bash
# Linux/Mac
export DATABASE_URL=jdbc:postgresql://localhost:5432/mydb
export API_KEY=my-secret-key

# Windows
set DATABASE_URL=jdbc:postgresql://localhost:5432/mydb
set API_KEY=my-secret-key
```

No addon: `.env` na raiz (`DATABASE_URL=...`). O Studio expõe via `System.getenv`.

### 2. `SYSTEM_PROPERTY` — propriedade do sistema Java

`value` = chave `-D` (pode ter ponto).

```java
@Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
private Integer serverPort;

@Value(value = "debug.enabled", type = ValueType.SYSTEM_PROPERTY, defaultValue = "false")
private Boolean debugEnabled;
```

Como definir a fonte:

```bash
java -Dserver.port=9090 -Ddebug.enabled=true -jar myapp.jar
```

```java
System.setProperty("server.port", "9090");
```

### 3. `SANKHYA_PARAM` — parâmetro do Sankhya Om

Substitui `MGECoreParameter.getParameter`. Use `param` (não `value`). `group` só aqui.

```java
@Value(param = "MAX_CONNECTIONS", type = ValueType.SANKHYA_PARAM, defaultValue = "10")
private Provider<Integer> maxConnections;
```

Com grupo:

```java
@Value(param = "TIMEOUT", group = "CONNECTION", type = ValueType.SANKHYA_PARAM, defaultValue = "30")
private Provider<Long> connectionTimeout;

@Value(param = "RETRY_COUNT", group = "HTTP", type = ValueType.SANKHYA_PARAM, defaultValue = "3")
private Integer retryCount;
```

A fonte é o cadastro de parâmetros do Om. Preferir `Provider<>` — a leitura do parâmetro pode ser custosa.

### 4. `UNDEFINED` — sem fonte; sempre o `defaultValue`

```java
@Value(value = "fallback", type = ValueType.UNDEFINED, defaultValue = "default-value")
private String fallbackValue; // sempre "default-value"
```

Teste ou constante injetável. Não use no lugar de parâmetro real de produção.

---

## Tipos suportados

A conversão de tipos é **automática**. `defaultValue` entra como `String`; o SDK converte para o tipo do campo. Gere o campo no tipo final — não injete `String` para depois fazer `parseInt`.

| Tipo Java | Exemplo a gerar |
| --- | --- |
| `String` | `@Value(...) private String texto;` |
| `Integer` / `int` | `@Value(...) private Integer numero;` |
| `Boolean` / `boolean` | `@Value(...) private Boolean flag;` |
| `Long` / `long` | `@Value(...) private Long id;` |
| `Double` / `double` | `@Value(...) private Double preco;` |
| `Float` / `float` | `@Value(...) private Float taxa;` |
| `Provider<T>` | `@Value(...) private Provider<String> lazy;` — os tipos acima como genérico |

### Conversão automática

```java
// String "8080" → Integer 8080
@Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
private Integer serverPort;

// String "true" → Boolean true
@Value(value = "debug.enabled", type = ValueType.ENV_VAR, defaultValue = "false")
private Boolean debugEnabled;

// String "3.14" → Double 3.14
@Value(value = "taxa", type = ValueType.SANKHYA_PARAM, defaultValue = "0.0")
private Double taxa;
```

Se a propriedade vier `"abc"` num `Integer`, o SDK cai no `defaultValue` (ex.: `"30"`).

Tipo fora dessa tabela → campo `null` ou falha na injeção. Não gere `BigDecimal`, `LocalDate` ou enum em `@Value`.

## Anatomia da anotação

Copie esta forma. Não omita `type` nem `defaultValue`.

```java
@Value(
    value = "PROPERTY_NAME",        // nome da propriedade (alternativa a param)
    param = "PROPERTY_NAME",        // nome do parâmetro (alternativa a value)
    group = "GROUP_NAME",           // só SANKHYA_PARAM
    type = ValueType.ENV_VAR,       // fonte — obrigatório
    defaultValue = "default"        // fallback — obrigatório
)
```

| Atributo | Obrigatório | Descrição |
| --- | --- | --- |
| `value` | um dos dois | Nome da propriedade. Alternativa a `param`. |
| `param` | um dos dois | Nome do parâmetro. Alternativa a `value`. **Tem precedência.** |
| `group` | não | Grupo do parâmetro. Só com `SANKHYA_PARAM`. |
| `type` | **sim** | `ENV_VAR`, `SYSTEM_PROPERTY`, `SANKHYA_PARAM` (ou `UNDEFINED`). |
| `defaultValue` | **sim** | Usado quando a propriedade não existe (e na conversão inválida). |

Ao menos um entre `value` e `param`. Se os dois existirem, **`param` vence**.

---

## Boas práticas (gerar assim)

### 1. Sempre forneça `defaultValue` utilizável

```java
// BOM: fallback que a aplicação consegue usar
@Value(value = "DATABASE_URL", type = ValueType.ENV_VAR, defaultValue = "jdbc:h2:mem:test")
private Provider<String> databaseUrl;

// EVITE: "" finge que tem fallback e quebra na hora de conectar
@Value(value = "DATABASE_URL", type = ValueType.ENV_VAR, defaultValue = "")
private Provider<String> databaseUrl;
```

### 2. Lazy (`Provider`) para opcional / condicional

```java
@Value(param = "FEATURE_FLAG", type = ValueType.SANKHYA_PARAM, defaultValue = "false")
private Provider<Boolean> featureFlag;

public void executar() {
    if (featureFlag.get()) {
        // só resolve se entrar aqui
    }
}
```

### 3. Eager para config crítica (sempre lida na subida)

```java
@Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
private Integer serverPort;

public void initialize() {
    int porta = serverPort; // já resolvido; sem .get()
}
```

### 4. Prefira o tipo específico (deixe a conversão automática trabalhar)

```java
// BOM
@Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
private Integer serverPort;

// EVITE — parse manual
@Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
private String serverPort;
```

### 5. Documente a fonte no Javadoc do campo

```java
@Component
public class EmailConfig {

    /**
     * URL do servidor SMTP.
     * Variável de ambiente: SMTP_HOST
     * Padrão: smtp.gmail.com
     */
    @Value(value = "SMTP_HOST", type = ValueType.ENV_VAR, defaultValue = "smtp.gmail.com")
    private Provider<String> smtpHost;

    /**
     * Porta do servidor SMTP.
     * Propriedade do sistema: smtp.port
     * Padrão: 587
     */
    @Value(value = "smtp.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "587")
    private Integer smtpPort;
}
```

---

## Exemplos para gerar código

### Pedido (eager + lazy no mesmo controller)

```java
@Controller(serviceName = "PedidoControllerSP")
public class PedidoController {

    @Value(value = "server.port", type = ValueType.SYSTEM_PROPERTY, defaultValue = "8080")
    private Integer serverPort;

    @Value(value = "DATABASE_URL", type = ValueType.ENV_VAR, defaultValue = "jdbc:h2:mem:test")
    private Provider<String> databaseUrl;

    @Value(param = "MAX_CONNECTIONS", type = ValueType.SANKHYA_PARAM, defaultValue = "10")
    private Provider<Integer> maxConnections;

    @Transactional
    public void processar(@Valid PedidoDTO pedido) {
        String url = databaseUrl.get();
        int port = serverPort;
        int pool = maxConnections.get();
        // ...
    }
}
```

### Feature flags (lazy + `SANKHYA_PARAM`)

```java
@Controller(serviceName = "PedidoControllerSP")
public class PedidoController {

    @Value(param = "VALIDACAO_AVANCADA_ATIVA", type = ValueType.SANKHYA_PARAM, defaultValue = "false")
    private Provider<Boolean> validacaoAvancadaAtiva;

    @Value(param = "NOVO_CALCULO_IMPOSTO", type = ValueType.SANKHYA_PARAM, defaultValue = "false")
    private Provider<Boolean> novoCalculoImposto;

    private final ValidadorAvancado validadorAvancado;
    private final CalculadoraImpostoV2 calculadoraV2;

    @Inject
    public PedidoController(ValidadorAvancado validadorAvancado, CalculadoraImpostoV2 calculadoraV2) {
        this.validadorAvancado = validadorAvancado;
        this.calculadoraV2 = calculadoraV2;
    }

    @Transactional
    public void processar(@Valid PedidoDTO pedido) {
        if (validacaoAvancadaAtiva.get()) {
            validadorAvancado.validar(pedido);
        }
        if (novoCalculoImposto.get()) {
            calculadoraV2.calcular(pedido);
        }
    }
}
```

### Pool / credenciais (tudo lazy, resolve só ao conectar)

```java
@Component
public class DatabaseConfig {

    @Value(value = "DATABASE_URL", type = ValueType.ENV_VAR, defaultValue = "jdbc:h2:mem:test")
    private Provider<String> databaseUrl;

    @Value(value = "DB_USERNAME", type = ValueType.ENV_VAR, defaultValue = "sa")
    private Provider<String> username;

    @Value(value = "DB_PASSWORD", type = ValueType.ENV_VAR, defaultValue = "")
    private Provider<String> password;

    @Value(param = "MAX_POOL_SIZE", type = ValueType.SANKHYA_PARAM, defaultValue = "20")
    private Provider<Integer> maxPoolSize;

    public Connection conectar() throws SQLException {
        return DriverManager.getConnection(
            databaseUrl.get(),
            username.get(),
            password.get()
        );
    }
}
```

---

## Anti-patterns desta referência (não gerar)

### Não use `@Value` em constante / `final`

```java
// MAL — não injeta
@Value(value = "APP_NAME", type = ValueType.ENV_VAR, defaultValue = "MyApp")
private final String APP_NAME;

// BOM
@Value(value = "APP_NAME", type = ValueType.ENV_VAR, defaultValue = "MyApp")
private String appName;
```

### Não misture lógica de negócio com configuração

`@Value` mora num `@Component` de config. O service injeta esse componente; não calcula imposto no mesmo tipo que lê o parâmetro.

```java
// MAL — regra acoplada no mesmo lugar do parâmetro
@Value(param = "TAXA_PADRAO", type = ValueType.SANKHYA_PARAM, defaultValue = "0.05")
private Double taxaPadrao;

public BigDecimal calcularTotal(BigDecimal valor) {
    return valor.multiply(BigDecimal.valueOf(1 + taxaPadrao));
}

// BOM
@Component
public class TaxaConfig {
    @Value(param = "TAXA_PADRAO", type = ValueType.SANKHYA_PARAM, defaultValue = "0.05")
    private Provider<Double> taxaPadrao;

    public Provider<Double> getTaxaPadrao() {
        return taxaPadrao;
    }
}

@Component
public class CalculadoraService {
    private final TaxaConfig taxaConfig;

    @Inject
    public CalculadoraService(TaxaConfig taxaConfig) {
        this.taxaConfig = taxaConfig;
    }

    public BigDecimal calcularTotal(BigDecimal valor) {
        Double taxa = taxaConfig.getTaxaPadrao().get();
        return valor.multiply(BigDecimal.valueOf(1 + taxa));
    }
}
```

### Não abuse de `defaultValue` complexo (JSON num único campo)

```java
// MAL
@Value(value = "CONFIG_JSON", type = ValueType.ENV_VAR,
       defaultValue = "{\"host\":\"localhost\",\"port\":8080,\"ssl\":true}")
private String configJson;

// BOM — um @Value por propriedade, tipo certo
@Value(value = "SERVER_HOST", type = ValueType.ENV_VAR, defaultValue = "localhost")
private String host;

@Value(value = "SERVER_PORT", type = ValueType.ENV_VAR, defaultValue = "8080")
private Integer port;

@Value(value = "SSL_ENABLED", type = ValueType.ENV_VAR, defaultValue = "true")
private Boolean sslEnabled;
```

### Classe sem estereótipo / `new`

```java
// MAL — @Value fica null
public class MinhaClasse {
    @Value(value = "APP_NAME", type = ValueType.ENV_VAR, defaultValue = "MyApp")
    private String valor;
}

// BOM
@Component
public class MinhaClasse {
    @Value(value = "APP_NAME", type = ValueType.ENV_VAR, defaultValue = "MyApp")
    private String valor;
}
```

### Outros (não gerar)

| Não | Sim |
| --- | --- |
| `MGECoreParameter.getParameter("X")` | `@Value(param = "X", type = SANKHYA_PARAM, defaultValue = "...")` |
| `System.getenv` / `Integer.parseInt` no método | campo `@Value` no tipo certo |
| `defaultValue = ""` como se fosse fallback | default que a app usa de verdade |
| `.get()` esperando reler o Om a cada request | cache por instância; `clearCache` só em teste |

Campo `null`: classe não gerenciada pelo Guice, tipo fora da tabela, ou `@Value` em `final`.

DI de componentes: [dependency-injection.md](dependency-injection.md).
