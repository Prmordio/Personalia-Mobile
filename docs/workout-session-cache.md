# Cache e persistência por etapas

O FlutterSecureStorage guarda o plano original, trocas, início, séries, peso,
observações e conclusão. O diário e a fila são isolados pelo `sub` do JWT.
As alterações chegam ao disco antes da primeira tentativa HTTP. O plano em
cache permite retomar sem conexão. A fila nativa não substitui o diário completo.

## Etapas

1. Iniciar treino/abrir a lista cria a sessão local e enfileira `POST /app/workout/sessions/:id`.
   O backend cria `WorkoutExecution` com `endedAt = null`. O horário inicial
   é enviado em UTC. A Home mostra Continuar treino imediatamente.
2. Somente um exercício concluído com peso preenchido (ou tempo de cardio)
   enfileira `PUT /app/workout/sessions/:id/exercises/:logId`. Edições mantêm
   o UUID do registro. Apagar o peso desfaz a conclusão e enfileira DELETE.
   Cancelar um exercício concluído remove seu registro e zera seu progresso,
   sem alterar os demais. O estado nativo também é atualizado.
3. Confirmar a finalização guarda o resumo imutável e enfileira
   `PATCH /app/workout/sessions/:id`, atualizando endedAt, mood e feedback.
   Nunca cria uma segunda execução.
4. Cancelar treino exige confirmação e enfileira `DELETE /app/workout/sessions/:id`.
   A exclusão em cascata remove os registros desta sessão. Envios de exercícios
   ainda não iniciados são dispensados; um início sem confirmação é preservado
   antes do cancelamento para ordenar tentativas após falha de conexão.

A fila usa operações imutáveis, FIFO por sessão, e só retira cada operação
após sucesso HTTP. Uma falha de exercício bloqueia a finalização, mas não
impede cancelar a sessão inteira. O diário ativo permanece disponível para
retomada mesmo depois dos ACKs intermediários. A remoção do diário detalhado
acontece após confirmar finalização/cancelamento no backend.

Há tentativa imediata em cada alteração relevante, ao abrir/retomar e a cada
60 segundos em primeiro plano. A sincronização não depende de manter Flutter
executando continuamente com a tela bloqueada. Logout preserva a fila da conta,
sem permitir envios por outra conta. Falha de disco impede envios não duráveis.

UUIDs estáveis das execuções e registros evitam duplicatas. O trainer serializa
as operações de uma sessão em transação com advisory lock PostgreSQL e valida
propriedade, peso e datas. Repetir finalização não sobrescreve os dados finais.
Treinos abertos não entram nas consultas de histórico de concluídos.

Payloads inteiros pendentes da versão anterior continuam usando `/app/workout/log`.
Rascunhos antigos são convertidos ao abrir, preservando registros e horário já
conhecido. Não há migração de banco: são usadas as PKs e FKs existentes.

## Publicação

Publicar trainer e gateway antes do novo app. A compilação nativa iOS
requer Xcode. Testar no aparelho: iniciar, sair/retomar, modo avião, concluir,
editar/cancelar concluído, finalizar/cancelar treino e reconectar.

## Separação de responsabilidades

O controller delega aos casos de uso `PersistAppWorkoutStageUseCase` e
`SaveAppWorkoutLogUseCase`, injetados pelo NestJS. Ambos dependem da porta
`AppWorkoutPersistencePort`, sem importar Prisma. O adaptador Prisma implementa
as transações, o advisory lock e a tradução de conflitos de escrita.

A ação finish guarda somente endedAt, mood e feedback na fila (além da
identificação da conta/sessão). O resumo completo permanece em lastCompletion
para recuperação local. O cliente HTTP também reduz operações finish antigas.
O feedback é opcional na tela de conclusão. A finalização só fica disponível
após o cache ter sido aberto e persistido com sucesso.
