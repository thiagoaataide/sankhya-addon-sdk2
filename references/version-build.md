# Versão do Addon Studio e `build.gradle`

Docs: [Getting started](https://developer.sankhya.com.br/docs/iniciando) · [Configurando o projeto](https://developer.sankhya.com.br/docs/03_conf_addonstudio) · [AutoDD](https://developer.sankhya.com.br/docs/autodd-gera%C3%A7%C3%A3o-autom%C3%A1tica-do-dicion%C3%A1rio-de-dados-data-dictionary)

## Gate obrigatório

Antes de gerar ou alterar código Java do SDK, leia o `build.gradle` da **raiz**.

Exija `br.com.sankhya.studio:gradle-plugin` **≥ 2.0.18**.

| Declaração | Veredito |
| --- | --- |
| `2.0.+` ou `2+` | Aceitar. Comentar no código que o resolvido precisa ser ≥ 2.0.18 |
| Pinned `2.0.18`, `2.0.19`, … | Aceitar |
| Pinned `2.0.0`–`2.0.17` | **Recusar.** Atualizar |
| `1.x` ou ausência do plugin | **Recusar.** Configurar 2.0 |

Forma recomendada (getting started + piso 2.0.18):

```groovy
buildscript {
    dependencies {
        classpath "br.com.sankhya.studio:gradle-plugin:2.0.+" // mínimo 2.0.18
        classpath "com.google.devtools.ksp:symbol-processing-gradle-plugin:2.0.0-1.0.24"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.0"
    }
}
```

A página de configuração do Studio também documenta `gradle-plugin:2+`. Qualquer uma das duas faixas 2.x serve, desde que a versão **resolvida** não fique abaixo de 2.0.18.

Se o plugin estiver velho: não gere `@Controller`, `@JapeEntity`, AutoDD nem MapStruct do SDK. Corrija o `build.gradle` primeiro e avise o usuário.

## Identificação e ambiente

```groovy
group = 'br.com.minhaempresa.addonexemplo' // não use grupos reservados: br, br.com, sankhya, com.sankhya, br.com.sankhya

snkmodule {
    serverFolder = System.getenv("WILDFLY_HOME") ?: '/opt/wildfly'
    plataformaMinima = "4.15"
}

addon {
    appKey = System.getenv("ADDON_APP_KEY")
    parceiroNome = "Minha Empresa"
}
```

`rootProject.name` em `settings.gradle` vira o contexto HTTP do addon. Evite o nome genérico `addon`.

## AutoDD + AutoDDL

```groovy
addon {
    autoDD = true
    autoDDL = true
}
```

- **AutoDD:** XML de Table/NativeTable a partir de `@JapeEntity`.
- **AutoDDL:** XML → DDL Oracle/MSSQL.
- Views, menus, dashboards, tree tables e filtros continuam no dicionário manual.

## Dependências de módulo

- `implementation`: jar já existe no Sankhya Om (não empacota).
- `moduleLib`: empacota no addon ( infla o artefato; use só quando a lib não está no monolito).

Segredos (`ADDON_APP_KEY`, `WILDFLY_HOME`) vão no `.env`, nunca commitados.
