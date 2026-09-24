# Addon Studio (cópia incorporada)

Conteúdo originado de **[snk-devcenter/addon-studio](https://github.com/snk-devcenter/addon-studio)** (plugin Sankhya Addon Studio 2.0).

| Campo | Valor |
| --- | --- |
| Versão upstream (tag) | ver `UPSTREAM_VERSION` |
| Commit upstream | ver `UPSTREAM_COMMIT` |
| Licença upstream | MIT — `LICENSE.upstream` |

Cópia vive neste repositório (`skills/studio/`, `agents/addon-studio/`). Atualizar:

```sh
./scripts/sync-addon-studio.sh
```

Isso recopia skills/agents, atualiza `UPSTREAM_*` e reaplica blocos **Referência GET (router)** nas skills sobrepostas.

Instalação no addon: `./install.sh` na raiz deste repo (ou via catálogo skillforge).
