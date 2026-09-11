# `@BeforeLoadListener`

Doc: https://developer.sankhya.com.br/docs/interceptando-buscas-com-beforeloadlistener

Intercepta o Finder JAPE **antes** da busca. Só em **instância criada pelo addon**. Proibido em nativas (`Parceiro`, `Produto`, `CabecalhoNota`, …). Uma classe por instância.

A entidade precisa existir no dicionário (XML **ou** `@JapeEntity`).

```java
import br.com.sankhya.jape.core.FinderListener;
import br.com.sankhya.jape.metadata.EntityMetaData;
import br.com.sankhya.jape.wrapper.FinderWrapper;
import br.com.sankhya.studio.annotations.BeforeLoadListener;

@BeforeLoadListener(instance = "MinhaInstancia")
public class MinhaInstanciaFiltroSeguranca implements FinderListener {

    @Override
    public void beforeExecute(EntityMetaData entity, FinderWrapper finder) throws Exception {
        finder.where("this.ATIVO = 'S'");
    }
}
```

Pode usar `@Inject`. `beforeExecute` roda em **toda** busca — sem query pesada. Filtro dinâmico: `JapeSession.getContext().getUserID()`.
