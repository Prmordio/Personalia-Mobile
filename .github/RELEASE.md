# Release mobile

PRs e pushes na `master` executam análise e testes, sem exigir mudança de
versão e sem criar tags.

Para publicar uma release:

1. Atualize `version: X.Y.Z+BUILD` no `pubspec.yaml` e faça merge na `master`.
   Use uma versão ainda não publicada e incremente o build para as lojas.
2. Crie e envie uma nova branch `release/*` a partir da `master` atualizada:

   ```bash
   git switch master
   git pull --ff-only origin master
   git switch -c release/1.0.0+42
   git push -u origin release/1.0.0+42
   ```

O workflow `Mobile Release` executa apenas no primeiro push da branch.
Valida que o commit pertence à `master`, executa análise e testes, cria a tag
`mobile/vX.Y.Z+BUILD` usando a versão do `pubspec.yaml` e chama `Mobile Deploy`
para Android (Play Store internal) e iOS (TestFlight). O nome da branch é
apenas descritivo; a versão vem do `pubspec.yaml`.

Pushes posteriores na mesma branch não criam releases. Para outra versão,
faça merge das alterações na `master` e crie uma nova branch de release.
As regras e os secrets do environment `production` continuam necessários.

Uma tag existente em outro commit bloqueia a release. Reexecutar o workflow
no mesmo commit reutiliza a tag, sem sobrescrevê-la. Se apenas uma plataforma
falhar, prefira reexecutar os jobs que falharam ou usar `Mobile Deploy`
manualmente com a tag e a plataforma desejadas, evitando reenviar um build
já publicado.

O deploy automático usa uma chamada de workflow reutilizável: tags criadas
com `GITHUB_TOKEN` não disparam outros workflows de push. Não é necessário PAT.
