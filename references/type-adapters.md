# Adaptadores de tipos

Doc: https://developer.sankhya.com.br/docs/%EF%B8%8F-adaptadores-de-tipos

Adaptadores convertem valores entre **três** representações:

| Camada | O que é |
| --- | --- |
| JSON | Gson (request/response do `@Controller`) |
| Objeto Java | campo da entidade / DTO |
| VO / Jape | valor persistido no banco |

Use `@GlobalTypeAdapter` **só** quando o tipo **não** tem adapter nativo (ex.: `ZonedDateTime`). Precedência: **global sobrescreve nativo**. Não reimplemente `BooleanAdapter`.

---

## Propósito das interfaces (adaptador global)

Anote a classe com `@br.com.sankhya.studio.stereotypes.GlobalTypeAdapter`. Implemente **uma ou mais**:

| Interface | Propósito |
| --- | --- |
| `TypeAdapter<T>` | Java ↔ Jape (`fromVO` / `toVO`) |
| `JsonSerializer<T>` | Java → JSON |
| `JsonDeserializer<T>` | JSON → Java |

`ZonedDateTime` precisa das três (Gson não tem suporte nativo; Jape guarda `Timestamp`).

```java
@GlobalTypeAdapter
public class ZonedDateTimeAdapter
        implements JsonSerializer<ZonedDateTime>, TypeAdapter<ZonedDateTime>, JsonDeserializer<ZonedDateTime> {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    @Override // tipo Jape: java.util.Timestamp
    public ZonedDateTime fromVO(Object o) {
        if (o == null) return null;
        return ((Timestamp) o).toInstant().atZone(ZoneId.systemDefault());
    }

    @Override
    public Object toVO(ZonedDateTime value) {
        return value == null ? null : Timestamp.from(value.toInstant());
    }

    @Override
    public void setType(Class<? extends ZonedDateTime> type) {}

    @Override
    public ZonedDateTime deserialize(JsonElement json, Type type, JsonDeserializationContext ctx) {
        try {
            return ZonedDateTime.parse(json.getAsString(), FORMATTER);
        } catch (Exception e) {
            throw new JsonParseException("Erro ao desserializar ZonedDateTime: " + json, e);
        }
    }

    @Override
    public JsonElement serialize(ZonedDateTime value, Type type, JsonSerializationContext ctx) {
        return new JsonPrimitive(FORMATTER.format(value));
    }
}
```

---

## Adaptadores nativos (aplicados automaticamente)

O SDK registra estes adapters quando **não** há global para o tipo. Prefira o tipo Java da coluna do meio — o nativo faz o resto.

| Adapter | Tipo Java (campo na entidade) | Tipo VO/Jape (banco) | Propósito / observações |
| --- | --- | --- | --- |
| `BooleanAdapter` | `Boolean` | String `"S"`/`"N"` na escrita; leitura aceita `Character` (`'S'`/`'N'`) e `String` | Boolean ↔ flag Sankhya. `'S'`/`"S"` = true. Não reimplemente. |
| `ByteArrayAdapter` | `byte[]` | Blob, `InputStream`, `byte[]` | Arquivo/binário em memória. Prefira `Binary` em FILE grande — [orm.md](orm.md). |
| `CharArrayAdapter` | `char[]` | String, Clob | Texto grande; ao salvar mantém `char[]`. Prefira `Text` em TEXT_BOX. |
| `DateAdapter` | `java.time.Temporal` (`LocalDate`, `LocalTime`, `LocalDateTime`) | `java.sql.Timestamp` | O tipo na leitura segue `setType`. |
| `DurationAdapter` | `java.time.Duration` | String ISO-8601 (`PT2H30M`) ou segundos (`Number`/`String`) | `toVO` = ISO; `fromVO` aceita ISO ou total de segundos. |
| `EnumAdapter` | `Enum<?>` | String/Number (`getValue()`) | Leitura: casa `getValue()`, senão `name()`. Escrita: `getValue()` se existir, senão `name()`. |
| `HashValueAdapter` | `HashValue` | String `"ALGORITHM:hex"` | Ex.: `SHA-256:a665...`. Sem algoritmo, assume SHA-256. |
| `InputStreamAdapter` | `java.io.InputStream` | Blob, `byte[]` | Leitura → stream; gravação → `byte[]`. |
| `InstantAdapter` | `java.time.Instant` | String ISO-8601 ou epoch millis | `toVO` = ISO; `fromVO` aceita ISO ou millis. |
| `JsonElementAdapter` | `com.google.gson.JsonElement` | String JSON | `""` vira `JsonObject` vazio; JSON inválido → `IllegalArgumentException`. |
| `JsonObjectAdapter` | `com.google.gson.JsonObject` | String JSON (objeto) | Só objeto; outro JSON → `IllegalArgumentException`. |
| `NumberAdapter` | `Number` (`int`, `long`, `double`, `float`, `short`, `byte`, `BigDecimal`) | `BigDecimal` | Banco em `BigDecimal` ↔ tipo do campo. |
| `PeriodAdapter` | `java.time.Period` | String ISO (`P...`) ou `"1Y-2M-15D"` | `toVO` = ISO; `fromVO` aceita os dois. |
| `URLAdapter` | `java.net.URL` | String | Valida e normaliza URL. |
| `UUIDAdapter` | `java.util.UUID` | String canônica ou `byte[16]` | `toVO` = string; `fromVO` aceita string e 16 bytes. |

---

## Esclarecimentos

- Campo `boolean`/`Boolean` na entidade: o nativo grava `S`/`N`. Não use `String ativo` com `"S"` se puder ser boolean.
- Datas modernas (`LocalDate`, `LocalDateTime`): `DateAdapter` — sem adapter extra.
- JSON em coluna texto: `JsonObject` / `JsonElement`, não `String` parseado na mão.
- Global para um tipo da tabela **substitui** o nativo inteiro. Implemente `TypeAdapter` + JSON se o tipo também viaja na API.
