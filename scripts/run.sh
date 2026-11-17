#!/usr/bin/env bash
# Roda o app em debug num aparelho Android conectado, escolhido numa lista.
#
#   scripts/run.sh                         # lista os aparelhos e pergunta qual usar
#   APP_DEVICE=<serial> scripts/run.sh     # pula a pergunta
#   APP_API_URL=<url> scripts/run.sh       # outro backend (padrão: gateway local via adb reverse)
#   APP_REBUILD=1 scripts/run.sh           # força o build mesmo sem mudanças nas fontes
#
# O localhost:3000 do aparelho vira o do host (adb reverse), então o backend local precisa
# estar no ar (`make dev-back-detached`).
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADB="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb"
API_URL="${APP_API_URL:-http://localhost:3000}"
export JAVA_HOME="${JAVA_HOME:-/snap/android-studio/current/jbr}"

die() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }
[ -x "$ADB" ] || ADB="$(command -v adb)" || die "adb não encontrado (defina ANDROID_HOME)."

DEVICE="${APP_DEVICE:-}"
if [ -z "$DEVICE" ]; then
  mapfile -t SERIALS < <("$ADB" devices | awk 'NR > 1 && $2 == "device" {print $1}')
  if [ "${#SERIALS[@]}" -eq 0 ]; then
    "$ADB" devices
    die "Nenhum aparelho pronto. Confira cabo, depuração USB e a autorização ('unauthorized' = aceite o aviso no celular)."
  fi

  echo "Aparelhos conectados:"
  for i in "${!SERIALS[@]}"; do
    s="${SERIALS[$i]}"
    model="$("$ADB" -s "$s" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
    version="$("$ADB" -s "$s" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
    printf '  %d) %-28s %s (Android %s)\n' "$((i + 1))" "$s" "${model:-?}" "${version:-?}"
  done

  if [ "${#SERIALS[@]}" -eq 1 ]; then
    DEVICE="${SERIALS[0]}"
    echo "Só um aparelho — usando $DEVICE."
  else
    while true; do
      read -rp "Escolha [1-${#SERIALS[@]}]: " choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#SERIALS[@]}" ]; then
        DEVICE="${SERIALS[$((choice - 1))]}"
        break
      fi
      echo "Opção inválida."
    done
  fi
fi

# Só faz sentido para o backend local; inofensivo se APP_API_URL apontar para outro lugar.
"$ADB" -s "$DEVICE" reverse tcp:3000 tcp:3000 >/dev/null || die "adb reverse falhou em $DEVICE."
if [[ "$API_URL" == http://localhost:3000* ]] && ! curl -sf -o /dev/null --max-time 3 "$API_URL/health"; then
  printf '\033[1;33m%s\033[0m\n' "⚠️  Gateway local fora do ar em :3000 — rode 'make dev-back-detached'. Seguindo mesmo assim."
fi

cd "$APP_DIR"

# --- APK em cache: só recompila (Gradle) se algo que entra no APK mudou -----------------------
# Impressão digital = conteúdo dos arquivos-fonte (lista do git: rastreados + novos, sem os
# ignorados — build/, local.properties, GeneratedPluginRegistrant…) + API_BASE_URL (vai compilado
# no APK) + versão do Flutter. Conteúdo, não mtime: o build reescreve arquivos gerados sem mudar
# nada. O APK fica numa cópia própria porque o `make app-e2e` sobrescreve o app-debug.apk padrão
# com o entrypoint de teste.
CACHE_DIR="$APP_DIR/build/app-run"
CACHED_APK="$CACHE_DIR/app-debug.apk"
STAMP="$CACHE_DIR/fingerprint"
FLUTTER_ROOT_DIR="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")"

fingerprint() {
  {
    git ls-files -co --exclude-standard -- lib assets android pubspec.yaml pubspec.lock l10n.yaml |
      sort | xargs -d '\n' sha1sum
    echo "API_BASE_URL=$API_URL"
    git -C "$FLUTTER_ROOT_DIR" rev-parse HEAD 2>/dev/null || cat "$FLUTTER_ROOT_DIR/version" 2>/dev/null || true
  } | sha1sum | cut -d' ' -f1
}

CURRENT="$(fingerprint)"
if [ -z "${APP_REBUILD:-}" ] && [ -f "$CACHED_APK" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$CURRENT" ]; then
  echo "✅ APK sem mudanças desde o último build ($(date -r "$CACHED_APK" '+%d/%m %H:%M')) — pulando o build."
else
  [ -n "${APP_REBUILD:-}" ] && echo "🔨 APP_REBUILD=1 — forçando build." || echo "🔨 Fontes mudaram — gerando APK de debug."
  flutter build apk --debug --dart-define=API_BASE_URL="$API_URL"
  mkdir -p "$CACHE_DIR"
  cp build/app/outputs/flutter-apk/app-debug.apk "$CACHED_APK"
  echo "$CURRENT" > "$STAMP"
fi

echo "📱 $DEVICE → $API_URL  (r = hot reload, R = restart, q = sair)"
# --use-application-binary: instala/abre esse APK sem passar pelo Gradle; hot reload segue
# funcionando (o Dart é compilado à parte). Se o mesmo APK já está no aparelho, nem reinstala.
exec flutter run --debug -d "$DEVICE" --use-application-binary "$CACHED_APK" \
  --dart-define=API_BASE_URL="$API_URL"
