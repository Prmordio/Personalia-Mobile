# Release notes ("O que há de novo")

Uma pasta por versão (a parte `X.Y.Z` do `version:` do `pubspec.yaml`), um arquivo por idioma
da ficha da App Store:

```
release-notes/
  3.4.3/
    pt-BR.txt
```

- **Publish Mobile Beta** falha se `release-notes/<versão>/` não existir ou tiver arquivo vazio
  ou com mais de 4000 caracteres (limite da Apple).
- **Promote Mobile Release** lê a pasta da `master` e envia o texto como "What's New" da versão
  no App Store Connect. Como lê da `master`, dá para corrigir o texto depois do beta sem rebuild.
- Use só idiomas que já existem na ficha da App Store (ex.: `pt-BR`, `en-US`, `es-ES`): um
  idioma novo aqui cria essa localização na ficha. Se a ficha tem mais de um idioma, todos
  precisam de arquivo — a Apple exige "What's New" em cada um.
