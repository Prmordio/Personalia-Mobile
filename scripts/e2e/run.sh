#!/usr/bin/env bash
# Testes integrados do app num aparelho Android (celular via USB ou emulador) contra o backend
# local (docker-compose.dev.yml).
#
#   scripts/e2e/run.sh                 # todos (integration_test/*_test.dart)
#   scripts/e2e/run.sh signup workout  # só os arquivos signup_test.dart e workout_test.dart
#   E2E_DEVICE=emulator-5554 scripts/e2e/run.sh   # força um aparelho (serial do `adb devices`)
#   KEEP_DATA=1 scripts/e2e/run.sh     # não apaga os usuários/emails de e2e no fim
#
# Aparelho: por padrão o celular conectado por USB (depuração USB ligada, tela desbloqueada).
# Sem celular, usa um emulador já rodando ou sobe o AVD personalia_e2e (E2E_AVD=nome).
# O celular alcança o gateway e o Mailpit do host por `adb reverse` (localhost:3000 e :8025).
#
# Pré-requisito: `make dev-fast` rodando (gateway, users, trainer, payment, notifier, mailpit,
# postgres). Atenção: o teste instala o build de debug por cima do app do aparelho e desloga
# a conta que estiver logada nele.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
ADB="$SDK/platform-tools/adb"
AVD="${E2E_AVD:-personalia_e2e}"
PACKAGE="com.personalia.personalia_app"
COMPOSE=(docker compose -f "$ROOT/docker-compose.dev.yml")
export JAVA_HOME="${JAVA_HOME:-/snap/android-studio/current/jbr}"

log() { printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }

log "Backend local"
curl -sf -o /dev/null http://localhost:3000/health || die "Gateway fora do ar em :3000 — rode 'make dev-fast'."
curl -sf -o /dev/null http://localhost:8025/api/v1/messages || die "Mailpit fora do ar em :8025."
[ "$("${COMPOSE[@]}" exec -T notifier-api printenv SMS_TRANSPORT 2>/dev/null | tr -d '\r')" = mailbox ] ||
  die "notifier-api sem SMS_TRANSPORT=mailbox — recrie com: docker compose -f docker-compose.dev.yml up -d notifier-api"

log "Aparelho"
physical_serial() { "$ADB" devices | awk 'NR > 1 && $2 == "device" && $1 !~ /^emulator-/ {print $1; exit}'; }
emulator_serial() { "$ADB" devices | awk '$1 ~ /^emulator-/ && $2 == "device" {print $1; exit}'; }
DEVICE="${E2E_DEVICE:-$(physical_serial)}"
if [ -z "$DEVICE" ]; then
  DEVICE="$(emulator_serial)"
fi
if [ -z "$DEVICE" ]; then
  echo "Nenhum celular nem emulador — iniciando o AVD $AVD (sem janela)."
  nohup "$SDK/emulator/emulator" -avd "$AVD" -no-window -no-audio -no-boot-anim -memory 2048 \
    -gpu swiftshader_indirect -no-snapshot-save >/tmp/personalia-e2e-emulator.log 2>&1 &
  for _ in $(seq 1 60); do DEVICE="$(emulator_serial)"; [ -n "$DEVICE" ] && break; sleep 5; done
  [ -n "$DEVICE" ] || die "Emulador não subiu (log: /tmp/personalia-e2e-emulator.log)."
fi
for _ in $(seq 1 60); do
  [ "$("$ADB" -s "$DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break; sleep 5
done

if [[ "$DEVICE" == emulator-* ]]; then
  # Dentro do emulador o host é 10.0.2.2 (padrão do app e dos testes).
  API_BASE_URL="http://10.0.2.2:3000"; MAILPIT_URL="http://10.0.2.2:8025"
else
  # Celular: o localhost dele vira o do host pelo cabo USB.
  "$ADB" -s "$DEVICE" reverse tcp:3000 tcp:3000 >/dev/null
  "$ADB" -s "$DEVICE" reverse tcp:8025 tcp:8025 >/dev/null
  API_BASE_URL="http://localhost:3000"; MAILPIT_URL="http://localhost:8025"
  # Tela ligada enquanto estiver no USB (o teste não desbloqueia PIN/senha).
  "$ADB" -s "$DEVICE" shell svc power stayon usb >/dev/null 2>&1 || true
  "$ADB" -s "$DEVICE" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
fi
echo "Usando $DEVICE ($("$ADB" -s "$DEVICE" shell getprop ro.product.model | tr -d '\r')) → $API_BASE_URL"

log "Usuário de teste (seed)"
SEED="$(python3 -I "$APP_DIR/scripts/e2e/seed_user.py")"
E2E_EMAIL="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["email"])' "$SEED")"
E2E_PASSWORD="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["password"])' "$SEED")"
echo "$E2E_EMAIL"

# A permissão de notificação (Android 13+) abre um diálogo nativo que o teste não consegue
# tocar; concedida assim que o app é instalado pelo flutter test.
grant_permissions() {
  for _ in $(seq 1 600); do
    if "$ADB" -s "$DEVICE" shell pm list packages 2>/dev/null | grep -q "$PACKAGE"; then
      "$ADB" -s "$DEVICE" shell pm grant "$PACKAGE" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
      "$ADB" -s "$DEVICE" shell appops set "$PACKAGE" SCHEDULE_EXACT_ALARM allow 2>/dev/null || true
    fi
    sleep 1
  done
}

if [ "$#" -gt 0 ]; then
  TESTS=(); for name in "$@"; do TESTS+=("integration_test/${name%_test.dart}_test.dart"); done
else
  mapfile -t TESTS < <(cd "$APP_DIR" && ls integration_test/*_test.dart | grep -v smoke_test)
fi

FAILED=()
cd "$APP_DIR"
for test in "${TESTS[@]}"; do
  log "flutter test $test"
  grant_permissions & GRANTER=$!
  if ! flutter test "$test" -d "$DEVICE" \
      --dart-define=API_BASE_URL="$API_BASE_URL" --dart-define=E2E_MAILPIT_URL="$MAILPIT_URL" \
      --dart-define=E2E_EMAIL="$E2E_EMAIL" --dart-define=E2E_PASSWORD="$E2E_PASSWORD"; then
    FAILED+=("$test")
  fi
  kill "$GRANTER" 2>/dev/null || true
done

if [[ "$DEVICE" != emulator-* ]]; then
  "$ADB" -s "$DEVICE" shell svc power stayon false >/dev/null 2>&1 || true
fi

if [ -z "${KEEP_DATA:-}" ]; then
  log "Limpando dados de e2e"
  python3 -I "$APP_DIR/scripts/e2e/seed_user.py" --cleanup
fi

if [ "${#FAILED[@]}" -gt 0 ]; then
  die "Falharam: ${FAILED[*]}"
fi
log "Todos os testes integrados passaram (${#TESTS[@]} arquivo(s))."
