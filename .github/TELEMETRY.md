# Crashlytics, Analytics e Performance Monitoring

`AppTelemetry` centraliza a integração. A coleta é ativada em release e
desativada em debug/profile por padrão. Para testar ou desativar explicitamente,
use `--dart-define=TELEMETRY_ENABLED=true` ou `false` no build.

## Eventos implementados

- `login`: autenticação concluída por OTP, senha, primeiro acesso ou biometria.
- `onboarding_completed`: preferências salvas, antes da oferta de trial/geração.
- `workout_started`: primeira ativação da sessão de treino pelo cronômetro.
- `workout_completed`: registro do treino confirmado pelo backend.
- `assistant_message_sent`: mensagem de texto aceita para envio ao assistente.
- `push_opened`: abertura de uma notificação remota, inclusive com app encerrado.
- `screen_view`: mudanças de rota no GoRouter, incluindo o ShellRoute.

Eventos não incluem parâmetros pessoais, mensagens, fotos, exercícios ou dados
de saúde. Rotas são limitadas a nomes conhecidos, sem queries ou IDs dinâmicos.
O identificador de publicidade está desabilitado. Analytics ainda utiliza os
identificadores de instalação e metadados padrão do SDK; não é coleta anônima.

## Erros e símbolos

Erros Flutter e assíncronos não tratados são registrados como fatais. Falhas
recuperáveis ao salvar o treino são registradas como não fatais. Apenas tipo,
stack trace e categoria da operação são enviados pelo código Dart: mensagens
de exceção podem conter tokens ou conteúdo de requisições e são omitidas.
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
não significa que o stream terminou. A duração de operações em streaming e
o tempo de renderização de cada tela Flutter não são medidos por esta integração.

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
