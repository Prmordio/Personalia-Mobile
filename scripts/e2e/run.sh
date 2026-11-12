#!/usr/bin/env bash
# Testes integrados do app no celular Android (via USB) contra o backend
# local (docker-compose.dev.yml).
#
#   scripts/e2e/run.sh                 # todos (integration_test/all_test.dart)
#   scripts/e2e/run.sh signup workout  # só os grupos signup e workout (= signup_test.dart, workout_test.dart)
#   E2E_DEVICE=RXCRC005XFJ scripts/e2e/run.sh   # força um celular (serial do `adb devices`)
#   KEEP_DATA=1 scripts/e2e/run.sh     # não apaga os usuários/emails de e2e no fim
#   E2E_TIMEOUT=900 scripts/e2e/run.sh # teto em segundos para a suíte (padrão 1800)
#   E2E_GRADLE_HEAP=3G E2E_GRADLE_WORKERS=4 scripts/e2e/run.sh  # build mais rápido, mais pesado
#
# Todos os arquivos rodam num app só (integration_test/all_test.dart, um grupo por arquivo):
# compila e instala uma vez. No fim imprime o resultado de cada teste (✅/❌ + primeiro erro) e
# grava resumo.md e o log em build/e2e-reports/<data-hora>/. Sai com erro se algum teste falhou.
#
# Aparelho: só o celular conectado por USB (depuração USB ligada, tela desbloqueada). Emulador
# não é usado: somado à stack Docker e ao build do Gradle, travava o notebook.
# O celular alcança o gateway e o Mailpit do host por `adb reverse` (localhost:3000 e :8025).
#
# Pré-requisito: `make dev-back-detached` (ou `dev-fast`) rodando (gateway, users, trainer, payment, notifier, mailpit,
# postgres, redis, agent-v2). Atenção: o teste instala o build de debug por cima do app do
# aparelho e desloga a conta que estiver logada nele.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
ADB="$SDK/platform-tools/adb"
PACKAGE="com.personalia.personalia_app"
COMPOSE=(docker compose -f "$ROOT/docker-compose.dev.yml")
export JAVA_HOME="${JAVA_HOME:-/snap/android-studio/current/jbr}"
# O APK é compilado aqui no notebook, junto com a stack Docker: com os limites do
# android/gradle.properties (3G de heap, todos os núcleos) a máquina de 12 GB travava.
# Build mais contido e com prioridade baixa (ver BUILD_NICE) — mais lento, máquina usável.
export GRADLE_OPTS="${GRADLE_OPTS:-} \"-Dorg.gradle.jvmargs=-Xmx${E2E_GRADLE_HEAP:-2G} -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m\" -Dorg.gradle.workers.max=${E2E_GRADLE_WORKERS:-2} -Dorg.gradle.project.kotlin.daemon.jvmargs=-Xmx768m"
BUILD_NICE=(nice -n 10 ionice -c 3)

log() { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }

# Uma suíte por vez: duas no mesmo celular disputam a instalação do APK, e a limpeza do fim de
# uma apaga os usuários de e2e que a outra ainda está usando.
# PID do script (não flock: o logcat que o flutter test deixa vivo herdaria a trava).
LOCK="${TMPDIR:-/tmp}/personalia-e2e.pid"
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK")" 2>/dev/null; then
  die "Já tem um e2e rodando (PID $(cat "$LOCK"), outro terminal?). Espere terminar."
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

log "Backend local"
curl -sf -o /dev/null http://localhost:3000/health || die "Gateway fora do ar em :3000 — rode 'make dev-back-detached'."
curl -sf -o /dev/null http://localhost:8025/api/v1/messages || die "Mailpit fora do ar em :8025."
[ "$("${COMPOSE[@]}" exec -T notifier-api printenv SMS_TRANSPORT 2>/dev/null | tr -d '\r')" = mailbox ] ||
  die "notifier-api sem SMS_TRANSPORT=mailbox — recrie com: docker compose -f docker-compose.dev.yml up -d notifier-api"

log "Aparelho"
physical_serial() { "$ADB" devices | awk 'NR > 1 && $2 == "device" && $1 !~ /^emulator-/ {print $1; exit}'; }
DEVICE="${E2E_DEVICE:-$(physical_serial)}"
if [ -z "$DEVICE" ]; then
  "$ADB" devices
  die "Nenhum celular pronto no USB. Confira cabo, tela desbloqueada e a autorização de depuração USB (estado 'unauthorized' acima = aceite o aviso no celular)."
fi
[[ "$DEVICE" != emulator-* ]] || die "E2E roda só no celular — emulador ($DEVICE) não é suportado."

# Restos de uma execução interrompida (portas do VM service redirecionadas, app aberto) fazem
# o flutter test instalar e abrir o app mas nunca conectar nele.
"$ADB" -s "$DEVICE" forward --remove-all >/dev/null 2>&1 || true
"$ADB" -s "$DEVICE" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true

# O localhost do celular vira o do host pelo cabo USB.
"$ADB" -s "$DEVICE" reverse tcp:3000 tcp:3000 >/dev/null
"$ADB" -s "$DEVICE" reverse tcp:8025 tcp:8025 >/dev/null
API_BASE_URL="http://localhost:3000"; MAILPIT_URL="http://localhost:8025"
# Tela ligada enquanto estiver no USB (o teste não desbloqueia PIN/senha).
"$ADB" -s "$DEVICE" shell svc power stayon usb >/dev/null 2>&1 || true
"$ADB" -s "$DEVICE" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true

# Bloqueado (PIN/senha), o app abre atrás da tela de bloqueio e não desenha nada — o teste só
# acusaria "Não apareceu ... TextField". Espera o desbloqueio antes de rodar.
wait_unlocked() {
  "$ADB" -s "$DEVICE" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
  for i in $(seq 1 60); do
    "$ADB" -s "$DEVICE" shell dumpsys window 2>/dev/null | grep -q 'isKeyguardShowing=true' || return 0
    [ "$i" = 1 ] && printf '\033[1;33m%s\033[0m\n' "Celular bloqueado — desbloqueie para continuar (espero 2 min)."
    sleep 2
  done
  die "Celular continuou bloqueado."
}
echo "Usando $DEVICE ($("$ADB" -s "$DEVICE" shell getprop ro.product.model | tr -d '\r')) → $API_BASE_URL"

# A permissão de notificação (Android 13+) abre um diálogo nativo que o teste não consegue
# tocar; concedida assim que o app é instalado pelo flutter test.
grant_permissions() {
  while true; do
    if "$ADB" -s "$DEVICE" shell pm list packages 2>/dev/null | grep -q "$PACKAGE"; then
      "$ADB" -s "$DEVICE" shell pm grant "$PACKAGE" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
      "$ADB" -s "$DEVICE" shell appops set "$PACKAGE" SCHEDULE_EXACT_ALARM allow 2>/dev/null || true
    fi
    sleep 1
  done
}

# Grupos do all_test.dart (= nome do arquivo de teste). Sem argumento, todos.
ALL_SUITES=(measures signup swap workout)
[ "$#" -gt 0 ] || set -- "${ALL_SUITES[@]}"
SUITES=()
for name in "$@"; do
  name="$(basename "${name%_test.dart}")"
  [[ " ${ALL_SUITES[*]} " == *" $name "* ]] || die "Grupo '$name' não existe no all_test.dart (${ALL_SUITES[*]})."
  SUITES+=("$name")
done

# Log + resumo no fim (scripts/e2e/report.py): build/e2e-reports/<data-hora>/.
REPORT_DIR="$APP_DIR/build/e2e-reports/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORT_DIR"
LOG_FILE="$REPORT_DIR/e2e.log"
# Falha intermitente do flutter test no celular: o leitor de logcat (de onde ele tira a porta do
# VM service) morre ou o DDS não sobe, e ele fica parado em vez de sair — às vezes com um desses
# erros, às vezes calado, com o app preso no splash. Nenhum teste rodou: o vigia encerra (na
# hora, ou se nenhum teste começar até E2E_CONNECT_TIMEOUT depois da instalação) e a suíte roda
# de novo uma vez.
NO_CONNECTION='Error waiting for a debug connection|The log reader stopped|Failed to start Dart Development Service'
NO_CONNECTION_MARK="$REPORT_DIR/no-connection"

# Teto da suíte: um teste preso (diálogo inesperado, serviço caído) não segura o terminal.
# --no-dds: com o DDS o flutter test às vezes nunca conectava no app (preso no splash). Sem ele
# o "loading" acusa um erro de goldens (streamListen ... GoldenFileComparator) que não é teste —
# o report.py ignora o "loading" e conta só os testes.
run_flutter_test() {
  : > "$LOG_FILE"
  rm -f "$NO_CONNECTION_MARK"
  local first_test="^[0-9]+:[0-9]+ \+[0-9]+.*: ($(IFS='|'; echo "${SUITES[*]}")) " installed_at=""
  ( "${BUILD_NICE[@]}" timeout "${E2E_TIMEOUT:-1800}" flutter test integration_test/all_test.dart \
      -d "$DEVICE" --no-dds --name "^($(IFS='|'; echo "${SUITES[*]}")) " \
      --dart-define=API_BASE_URL="$API_BASE_URL" --dart-define=E2E_MAILPIT_URL="$MAILPIT_URL" \
      --dart-define=E2E_USERS="$E2E_USERS" --dart-define=E2E_PASSWORD="$E2E_PASSWORD" 2>&1 |
    tee "$LOG_FILE" ) &
  local run=$!
  while kill -0 "$run" 2>/dev/null; do
    if [ -z "$installed_at" ] && grep -qE '^Installing .*[0-9]s$' "$LOG_FILE" 2>/dev/null; then
      installed_at=$(date +%s)
    fi
    local silent=0
    if [ -n "$installed_at" ] && ! grep -qE "$first_test" "$LOG_FILE" 2>/dev/null &&
        [ $(( $(date +%s) - installed_at )) -gt "${E2E_CONNECT_TIMEOUT:-120}" ]; then
      silent=1
    fi
    if [ "$silent" = 1 ] || grep -qE "$NO_CONNECTION" "$LOG_FILE" 2>/dev/null; then
      touch "$NO_CONNECTION_MARK"
      sleep 5
      pkill -f "flutter_tools.snapshot test integration_test/all_test.dart" || true
      break
    fi
    sleep 3
  done
  wait "$run"
}

cd "$APP_DIR"
# Usuário novo por grupo: um fluxo (treino finalizado, troca permanente no plano) não muda o
# ponto de partida do outro — cada grupo roda igual, em qualquer ordem. Vão todos num
# --dart-define só (E2E_USERS="measures=email;swap=email"), lido pelo E2eEnv.seededEmail.
E2E_USERS=""
for name in "${SUITES[@]}"; do
  log "Usuário de teste (seed) para $name"
  SEED="$(python3 -I "$APP_DIR/scripts/e2e/seed_user.py" 2>&1)" || die "seed falhou: $SEED"
  email="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["email"])' "$SEED")"
  E2E_PASSWORD="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["password"])' "$SEED")"
  echo "$email"
  E2E_USERS="${E2E_USERS:+$E2E_USERS;}$name=$email"
done

log "flutter test integration_test/all_test.dart (${SUITES[*]})"
wait_unlocked
grant_permissions & GRANTER=$!
set +e
for attempt in 1 2; do
  run_flutter_test
  status=$?
  [ -f "$NO_CONNECTION_MARK" ] || break
  [ "$attempt" = 1 ] && log "Não conectou no app — tentando de novo"
  "$ADB" -s "$DEVICE" forward --remove-all >/dev/null 2>&1
  "$ADB" -s "$DEVICE" shell am force-stop "$PACKAGE" >/dev/null 2>&1
  wait_unlocked
done
echo "exit $status" > "$REPORT_DIR/e2e.status"
set -e
kill "$GRANTER" 2>/dev/null || true

"$ADB" -s "$DEVICE" shell svc power stayon false >/dev/null 2>&1 || true

if [ -z "${KEEP_DATA:-}" ]; then
  log "Limpando dados de e2e"
  python3 -I "$APP_DIR/scripts/e2e/seed_user.py" --cleanup
fi

log "Resultado"
python3 -I "$APP_DIR/scripts/e2e/report.py" "$REPORT_DIR"
