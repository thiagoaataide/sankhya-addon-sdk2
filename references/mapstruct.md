# Mapeamento de objetos com MapStruct

Doc: https://developer.sankhya.com.br/docs/%EF%B8%8Fmapeamento-de-objetos-com-mapstruct

O SDK integra **MapStruct** para converter DTO ↔ entidade `@JapeEntity` em compile-time (sem reflection, sem `get`/`set` na mão). Não existe um terceiro “modelo de domínio” no caminho padrão:

```
Request DTO  →  @JapeEntity  →  Response DTO
```

Não exponha a entidade no `@Controller`. Gson serializa fields — campos `@Lazy` não saem certos sem mapper. Ver [orm.md](orm.md) e [controller.md](controller.md).

---

## Detecção automática

O processador do Studio **só liga** se MapStruct estiver no classpath.

```
✅ MapStruct detectado no classpath. MapperProcessor será ativado.
ℹ️ MapStruct não detectado no classpath. MapperProcessor será ignorado.
```

Sem a dependência, `@Mapper` é ignorado — não quebra o build, mas o mapper **não entra no Guice**.

Kotlin/KSP: **sem suporte** oficial.

---

## Dependências (`build.gradle` do módulo)

```groovy
dependencies {
    implementation 'org.mapstruct:mapstruct:1.5.5.Final'
    annotationProcessor 'org.mapstruct:mapstruct-processor:1.5.5.Final'

    compileOnly 'org.projectlombok:lombok:1.18.30'
    annotationProcessor 'org.projectlombok:lombok:1.18.30'
    annotationProcessor 'org.projectlombok:lombok-mapstruct-binding:0.2.0'
}

tasks.withType(JavaCompile) {
    options.compilerArgs += [
        '-Amapstruct.defaultComponentModel=cdi',
        '-Amapstruct.unmappedTargetPolicy=IGNORE'
    ]
}
```

| Flag | Efeito |
| --- | --- |
| `defaultComponentModel=cdi` | implementação detectável pelo SDK/Guice (doc oficial) |
| `unmappedTargetPolicy=IGNORE` | campo target sem `@Mapping` não falha o compile |
| `lombok-mapstruct-binding` | getters Lombok visíveis para o processor |

A doc oficial recomenda `componentModel = "cdi"` **na interface**. Se o `build.gradle` do projeto já fixar `jakarta` (plugin snk-devcenter), **não** declare `componentModel` de novo no `@Mapper` — sobrescreve o global. Siga o padrão que já compila no addon.

`implementation` = API. `annotationProcessor` = gerador. Falta o processor → interface sem impl → `UnsatisfiedDependencyException`.

---

## Interface `@Mapper`

```java
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "cdi")
public interface UserMapper {

    @Mapping(source = "nomeUsuario", target = "username")
    @Mapping(source = "ativo", target = "enabled")
    UserDTO toDTO(UserJapeEntity entity);

    @Mapping(target = "nomeUsuario", source = "username")
    @Mapping(target = "ativo", source = "enabled")
    UserJapeEntity toEntity(UserDTO dto);

    List<UserDTO> toDTOList(List<UserJapeEntity> entities);
}
```

Campo com o **mesmo nome** mapeia sozinho. Nomes diferentes exigem `@Mapping(source, target)`.

A doc mostra `UserMapper INSTANCE = Mappers.getMapper(...)`. Em classe gerenciada (`@Controller`, `@Component`) **injete** o mapper. `INSTANCE` só se não houver DI.

---

## Injeção

```java
@Component
public class UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    @Inject
    public UserService(UserRepository userRepository, UserMapper userMapper) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
    }

    @Transactional
    public UserDTO findUserById(Long userId) {
        UserJapeEntity userEntity = userRepository.findByPK(userId)
            .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));
        return userMapper.toDTO(userEntity);
    }

    public void createUser(UserDTO userDTO) {
        UserJapeEntity userEntity = userMapper.toEntity(userDTO);
        userRepository.save(userEntity);
    }
}
```

No controller: `mapper.toPedido(request)` entra no service; `mapper.toResponse(salvo)` volta na API.

Convenção comum de nomes:

| Direção | Método |
| --- | --- |
| Request → entidade | `toPedido(PedidoRequest dto)` |
| Entidade → Response | `toCriarResponse(Pedido pedido)` |
| lista | `toDTOList(List<Entidade> list)` |

---

## `@Mapping` — casos frequentes

```java
@Mapping(source = "idExterno", target = "idOrigem")
@Mapping(source = "cultura.id", target = "culturaId")      // nested
@Mapping(target = "ativo", constant = "true")
@Mapping(target = "id", ignore = true)                     // PK gerada
Pedido toPedido(CriarPedidoRequest request);
```

Atualizar entidade existente (`@MappingTarget`):

```java
@Mapping(target = "id", ignore = true)
void update(@MappingTarget Pedido entidade, AtualizarPedidoRequest dto);
```

---

## Troubleshooting (doc oficial)

**`UnsatisfiedDependencyException` ao injetar o mapper**

1. `mapstruct` em `implementation` e `mapstruct-processor` em `annotationProcessor`.
2. `@Mapper(componentModel = "cdi")` **ou** o global do `build.gradle` (`cdi` / `jakarta` / `default`).
3. `./gradlew clean build` — processor às vezes não roda no incremental.

**Processor não parece rodar**

1. Conflito de annotation processors no `build.gradle`.
2. `./gradlew clean --refresh-dependencies`.
3. Sem `lombok-mapstruct-binding`, mapper + Lombok `@Data` gera impl vazia.

Log do Studio na compilação confirma se o `MapperProcessor` ativou.

---

## Anti-patterns

| Não | Sim |
| --- | --- |
| `dto.setX(entity.getX())` na mão | `@Mapper` |
| devolver `@JapeEntity` no controller | `toResponse(...)` |
| `Mappers.getMapper` em `@Component` | `@Inject` no construtor |
| POJO de domínio extra por default | DTO ↔ entidade |
| Kotlin/KSP | Java + `annotationProcessor` |
| MapStruct para JSON custom | [type-adapters.md](type-adapters.md) (`@GlobalTypeAdapter`) |

Docs externas: [mapstruct.org](https://mapstruct.org/) · DI do SDK: [dependency-injection.md](dependency-injection.md).
