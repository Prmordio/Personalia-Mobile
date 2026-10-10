# Release mobile pelo GitHub Actions

PRs e pushes na `master` executam análise e testes. Não criam tags nem
publicam builds. Branches `release/*` não são necessárias e não disparam nada.

## Publicar beta

1. Atualize `version: X.Y.Z+BUILD` no `pubspec.yaml` em um PR comum e faça
   merge na `master`. Incremente BUILD para cada novo binário distribuído.
2. Em Actions, selecione **Publish Mobile Beta** → **Run workflow**.
3. Selecione a branch **master**. Deixe `commit` vazio para usar a master
   atual, ou informe um SHA que pertença ao histórico da master.
4. Selecione `both`, `android` ou `ios`.

O workflow valida origem/versão, executa análise/testes, cria a tag imutável
`mobile/vX.Y.Z+BUILD` e publica Android → Play Internal; iOS → TestFlight.
A tag permanece se um build falhar, para permitir recuperação. Uma tag
existente em outro commit bloqueia a publicação.

AAB e IPA ficam nos artifacts por 90 dias. Depois do envio às lojas, cada
plataforma gera um registro `beta-PLATAFORMA-TENTATIVA` contendo tag, versão,
commit e run ID. O resumo de cada job mostra o link para promoção e o run ID.
O disparo manual da promoção representa a decisão de que o beta foi testado.

## Promover para produção

1. Teste os builds no Play Internal e TestFlight e aguarde o processamento
   do build pela Apple.
2. Abra **Promote Mobile Release** → **Run workflow**, na branch **master**.
3. Informe a tag exata e o `beta_run_id` do resumo da publicação beta.
4. Selecione as plataformas. Para Android, `android_rollout=0.1` atende 10%
   dos usuários; `1` libera para 100%. Para iOS, escolha se a Apple deve
   publicar automaticamente após aprovar a revisão.

A promoção verifica os registros beta de cada plataforma e compara o commit
com a tag atual. Não compila nem envia AAB/IPA novamente.
Android promove exclusivamente o versionCode selecionado do Internal para
produção. Se ele já saiu do Internal, o workflow falha sem promover outro build.
iOS seleciona exatamente a versão e o build enviados ao TestFlight e submete
à revisão da App Store. Com publicação automática desativada, o lançamento
após aprovação é feito no App Store Connect.

Metadados, screenshots, privacidade, informações para revisão e requisitos
de compliance devem estar completos nas lojas; o workflow não os substitui.
O token App Store Connect precisa permitir submissão, e a service account
da Play Store precisa ter permissão para publicar em produção.

## Recuperação e rollout

Se somente uma plataforma falhar, reexecute os jobs que falharam. Também é
possível publicar beta novamente selecionando o mesmo commit e somente a
plataforma pendente. Não reenvie uma plataforma que já publicou o mesmo build.
Reexecutar apenas jobs falhos mantém os registros da outra plataforma no
mesmo run. Execuções separadas têm run IDs separados: promova cada plataforma
com seu respectivo run ID.

Se o envio à loja funcionar mas o registro de confirmação falhar, confira a
loja e recupere o registro antes de promover; não reenvie o binário.
Releases anteriores a este fluxo não possuem comprovação beta e não podem
ser promovidas por ele. Registros expirados após 90 dias também bloqueiam a
promoção automatizada; nesse caso use as consoles das lojas.
Para aumentar um rollout já iniciado, use a Play Console. Este workflow faz
a promoção inicial; não automatiza alterações posteriores do rollout.

## Configuração e compatibilidade

Os workflows manuais precisam estar na branch padrão para aparecer na aba
Actions. Execute-os na master; selecionar outra branch pula a execução.
Beta e promoção usam o environment `production` e os secrets existentes,
sem exigir migração de credenciais. Regras de aprovação desse environment
se aplicam a ambos os fluxos.

Secrets reutilizados: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAY_STORE_JSON_KEY`,
`PERSONALIA_API_URL`, `WHATSAPP_BOT_NUMBER`, `DISTRIBUTION_CERT_BASE64`,
`CERT_P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `APPLE_TEAM_ID`,
`APP_STORE_ISSUER_ID`, `APP_STORE_API_KEY_ID`, `APP_STORE_API_PRIVATE_KEY`.
Nenhum secret novo é necessário para a promoção.

Beta e promoção compartilham um grupo de concorrência. GitHub Actions mantém
uma execução ativa e uma pendente por grupo; não enfileire várias solicitações,
pois a pendente pode ser substituída. A execução ativa não é cancelada.

A tag é criada com `GITHUB_TOKEN`, e o build é chamado como workflow
reutilizável. Não depende de eventos de push de tag nem requer PAT.
