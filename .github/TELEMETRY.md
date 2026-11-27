# Crashlytics, Analytics, Performance e In-App Messaging

`AppTelemetry` centraliza a integração. A coleta é ativada em release e
desativada em debug/profile por padrão. Para testar ou desativar explicitamente,
use `--dart-define=TELEMETRY_ENABLED=true` ou `false` no build.

## Eventos implementados

Lista completa, com parâmetros e significado: [FIREBASE-METRICAS.md §4](../../FIREBASE-METRICAS.md).
Resumo: `login`, `sign_up`, `onboarding_completed`, `workout_started`,
`workout_completed`, `assistant_message_sent`, `assistant_reply`,
`assistant_photo_sent`, `paywall_viewed`, `purchase_started`,
`purchase_cancelled`, `purchase_failed`, `purchase_completed`,
`restore_completed`, `push_opened`, `update_prompt_dismissed`,
`update_store_opened`, `screen_view`.

Parâmetros passam por `AppTelemetry.sanitizeParams` e são sempre valores
fechados (enums, booleanos, números): nunca mensagens, fotos, exercícios, ids ou
dados de saúde. Rotas são limitadas a nomes conhecidos, sem queries ou IDs.
O identificador de publicidade está desabilitado.

## Identidade e segmentos

`UserTelemetrySync` ([user_telemetry_sync.dart](../lib/core/telemetry/user_telemetry_sync.dart))
roda no início do app, no login/logout e após compra:
- `user_id` do Analytics e User ID do Crashlytics = JWT `sub` (UUID interno da
  conta, pseudônimo; nunca telefone/email/CPF). Limpo no logout.
- User properties (espelhadas como custom keys do Crashlytics): `plan`,
  `has_whatsapp_link`, `training_focus`, `internal_tester`.
- Tópico FCM `plan_<plano>` (apenas um por vez; todos removidos no logout).

Com isso os dados de uso/diagnóstico são **vinculados ao usuário**: o Data safety
da Play e o App Privacy da Apple precisam declarar isso.

## Erros e símbolos

Erros Flutter e assíncronos não tratados são registrados como fatais. Não
fatais: `save_workout`, `cache_workout`, `store_billing_<etapa>_<código>` e, via
`HttpErrorInterceptor`, `http_5xx <MÉTODO> <endpoint>`/`http_timeout …` (no
máximo 1 por endpoint a cada 5 min). Apenas tipo, stack trace e categoria são
enviados: mensagens de exceção podem conter tokens ou conteúdo de requisições e
são omitidas. Texto variável e seguro (ex.: mensagem da loja) vai na custom key
`error_detail`. Também são enviadas as keys `screen` e `workout_active` e uma
trilha de logs (`nav:<tela>`, `http <status> <endpoint>`), sem payload.
Falhas de transmissão de telemetria não interrompem essas operações.

O plugin Gradle Crashlytics integra os símbolos/mapeamento Android ao build.
O workflow beta envia os dSYMs do archive iOS pelo `upload-symbols` do pod,
antes do envio ao TestFlight, e guarda os dSYMs como artifact por 90 dias.
Releases históricas sem Crashlytics pulam o upload. Builds feitos fora do CI
precisam enviar seus próprios dSYMs. Não usamos obfuscação Dart; se adicionada,
também será necessário preservar/enviar os arquivos de `--split-debug-info`.

## Ativação e verificação

1. No projeto Firebase existente, confirme que Google Analytics está habilitado
   em Configurações → Integrações. Não foi alterada configuração remota nesta tarefa.
2. Abra Crashlytics e conclua a configuração do app, se o console solicitar.
3. Publique um novo build e navegue/faça login para validar Analytics.
4. Verifique os eventos em Analytics e relatórios de erros no Crashlytics.
   O processamento não é necessariamente imediato.

Em Android, para DebugView, além de habilitar TELEMETRY_ENABLED no build:

```bash
adb shell setprop debug.firebase.analytics.app com.personalia.personalia_app
```

Para desativar DebugView:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

Não há botão de crash em produção. Testes locais verificam sanitização de rotas
e execução sem Firebase; a entrega real precisa ser validada em um aparelho.

Referências: [Crashlytics Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-started),
[Analytics Flutter](https://firebase.google.com/docs/analytics/flutter/get-started),
[Símbolos Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-deobfuscated-reports).

## Performance Monitoring

`PerformanceInterceptor` instrumenta as requisições do Dio compartilhado,
medindo duração e status HTTP. Cada requisição tem sua própria métrica,
encerrada em sucesso ou erro, sem alterar o resultado da chamada.
Não copia headers, corpos ou parâmetros para o Firebase. URLs das métricas
manuais removem credenciais, queries e fragmentos; segmentos desconhecidos
são substituídos por `_`, evitando IDs ou dados pessoais no caminho.
O tamanho dos corpos não é estimado serializando conteúdo.

O interceptor ignora `ResponseType.stream` (chat SSE), pois receber os headers
não significa que o stream terminou. Para o chat existe o trace
`assistant_first_token`. Outros traces personalizados: `app_start` (métrica
`ms_to_first_screen`, medida desde o `main()`) e `workout_today_ready`. O tempo
de renderização genérico de cada tela Flutter não é medido.

O SDK usa `TELEMETRY_ENABLED`, com o mesmo padrão de release dos outros dois
produtos. A configuração nativa começa com coleta desativada e o Dart a ativa
na inicialização; isso evita coletar antes da decisão, mas pode limitar métricas
de startup anteriores à inicialização. O SDK também oferece instrumentação
nativa automática: seus padrões de URL são definidos pelo Firebase, separados
da sanitização aplicada pelo interceptor. Não interprete métricas automáticas
e manuais do mesmo endpoint como requisições adicionais de usuários.

Depois de publicar, abra **Performance** no Firebase Console e execute ações
como carregar treino e relatórios. As métricas são enviadas em lotes e podem
demorar a aparecer. Não foi adicionada coleta de conteúdo ou informação de saúde.

Referência: [Performance Monitoring Flutter](https://firebase.google.com/docs/perf-mon/flutter/get-started).

## In-App Messaging e Remote Config

`firebase_in_app_messaging` segue o mesmo `TELEMETRY_ENABLED` (coleta nativa
desligada no manifest/Info.plist até o Dart decidir) e fica suprimido durante um
treino em andamento. Campanhas são criadas no console.

Chaves do Remote Config (kill switches `assistant_enabled` e
`execution_analysis_enabled`, faixa `maintenance_message`, lista
`internal_tester_email_hashes`): ver
[docs/firebase-rotina-e-melhorias.md](../../docs/firebase-rotina-e-melhorias.md) §3.
