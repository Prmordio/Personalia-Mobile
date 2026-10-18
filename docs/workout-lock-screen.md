# Controles de treino na tela bloqueada

O treino de musculação usa a mesma sessão para os controles do app e da tela
bloqueada. A sessão nativa persiste exercício, série, repetições do plano, fase e
horários. Ela aceita ações mesmo com Flutter suspenso; ao retomar, o app lê o
progresso e atualiza os providers existentes. Carga e observações continuam no app.

Fluxo: fazer a série → iniciar descanso → contagem regressiva no botão → aviso de
próxima série → botão "Iniciar descanso" novamente. Iniciar descanso marca a série
que acabou de ser feita e mantém os X e o contador sincronizados. Não existe
cronômetro crescente de execução. O último descanso é entre exercícios; ao
terminar, o cartão oferece o próximo exercício. Cardio mantém o fluxo existente.
Pesquisar e trocar exercício continuam exclusivamente no aplicativo.

Android usa um serviço nativo em primeiro plano somente durante o descanso,
com notificação pública e controles. O contador no botão é atualizado a cada
segundo e limitado a zero, inclusive sem permissão de alarme exato. Um wake lock
limitado ao tempo restante permite encerrar o descanso com a tela apagada.
Pausar, encerrar ou finalizar o descanso libera o serviço e o wake lock.
O alarme local continua como recuperação, sem substituir o contador por horário
fixo. Notificações precisam estar permitidas. Tocar no contador pausa/continua,
sem marcar outra série. No zero, o aviso toca uma vez e o botão volta para
"Iniciar descanso" (ou próximo exercício após a última série).

A conclusão do último descanso sincroniza também a finalização do exercício,
retirando-o da lista de pendentes e preservando carga/observações no resumo.
Contadores completos deixados pela versão anterior são reconciliados ao abrir
a lista, respeitando um eventual descanso final ainda em andamento.

O serviço Android declara `specialUse` para o contador iniciado pelo usuário.
Para publicar no Google Play, declarar esse uso também na seção de serviços
em primeiro plano do Play Console, com a justificativa do manifesto.

iOS 17+ usa ActivityKit, WidgetKit e LiveActivityIntent, incluindo Dynamic Island.
Em versões anteriores, os controles permanecem disponíveis dentro do aplicativo.
A extensão não precisa de App Groups: os intents executam no processo do app e a
interface recebe o snapshot pelo ActivityKit. O sistema e o usuário podem
desativar/dispensar a Live Activity.

## Assinatura iOS

A extensão está incluída no projeto Xcode e no archive de Runner. Para distribuir:

1. Registrar o App ID `com.personalia.personalia-app.WorkoutLive` na equipe Apple.
2. Criar um perfil App Store para esse identificador, com o certificado de
   distribuição usado pelo app. Nome sugerido: `PersonaliA WorkoutLive AppStore`.
3. Adicionar o perfil em base64 ao secret `WORKOUT_LIVE_PROFILE_BASE64` do GitHub.

O workflow instala e valida os dois perfis e configura a assinatura por target.
O perfil do Runner existente continua separado. Para testes locais no Xcode,
selecionar a equipe de desenvolvimento do target WorkoutLive.

## Verificação em aparelhos

- Tocar em Iniciar descanso; bloquear o aparelho; conferir o contador no botão.
- Conferir série e repetições ao voltar ao app, sem contar a mesma série duas vezes.
- Começar descanso; adicionar 30 s; conferir cronômetro e aviso de término.
- Esperar chegar a zero; conferir o aviso de próxima série e o retorno de Iniciar descanso.
- Iniciar próximo exercício pelo cartão e conferir o exercício exibido no app.
- Registrar carga/observações e finalizar exercício/treino pelo fluxo existente.
- Negar notificações/Live Activities e conferir que o treino continua no app.
- Encerrar o processo, usar os controles nativos e reabrir para conferir o progresso.
- Conferir remoção do cartão ao finalizar treino, sair da conta ou trocar exercício.

## Registro e idioma

Peso e observações continuam editáveis após a conclusão das séries.
Os exercícios concluídos podem ser reabertos pela seção de concluídos para
corrigir o registro. O resumo automático aguarda o retorno à lista de treino,
para não interromper o preenchimento no último exercício.
Os controles no app e o snapshot nativo usam as traduções ARB (pt/en/es).
Trocar o idioma atualiza os textos da sessão existente sem reiniciar descanso,
alterar séries ou invalidar ações já exibidas.

O horário de início (`startedAt`) é persistido ao iniciar o treino e acompanha
a sessão ao trocar de exercício. Os controles nativos recebem esse horário. Ao retomar, a duração usa esse horário,
preservando um início anterior já conhecido pelo app. Snapshots antigos sem esse
campo usam o último anchor disponível como aproximação; não é possível
recuperar retroativamente um início que a versão anterior não salvou.
Reabrir registros concluídos entra somente em edição: não prepara uma nova
sessão, não oferece ações do descanso atual e não o encerra ao salvar.

## Peso obrigatório para avançar

O próximo exercício só é liberado após preencher o peso no app.
A validação ocorre no Flutter e nos handlers nativos, incluindo botões antigos
que ainda estejam visíveis. Apagar o peso bloqueia novamente o avanço.
Na tela bloqueada, falta de peso mostra o aviso de preenchimento e oculta o
avanço. O registro é persistido na sessão e restaurado ao reabrir o app.
O fim das séries sem peso mantém o exercício nos pendentes para completar o
registro; o aviso e a contagem do descanso continuam funcionando normalmente.
