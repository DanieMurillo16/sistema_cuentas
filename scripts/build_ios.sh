#!/usr/bin/env bash
# Compila y instala la app en un iPhone real (o genera el .ipa).
#
#   bash scripts/build_ios.sh devices          lista los dispositivos conectados
#   bash scripts/build_ios.sh run [ID]         instala y abre la app (modo release) en ese iPhone
#   bash scripts/build_ios.sh build            compila (release) sin instalar
#   bash scripts/build_ios.sh ipa              genera el .ipa en build/ios/ipa/
#
# La dirección del servidor sale de .env.json (API_BASE_URL); nunca del código.
# Guía completa: docs/IOS.md
set -euo pipefail
cd "$(dirname "$0")/.."

# CocoaPods exige UTF-8 en la terminal.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

fallar() { echo "✗ $1" >&2; exit 1; }

[ -f .env.json ] || fallar "Falta .env.json (copia .env.json.ejemplo y pon API_BASE_URL)."
grep -q '"API_BASE_URL"' .env.json || fallar ".env.json no tiene API_BASE_URL."
command -v xcodebuild >/dev/null || fallar "Falta Xcode."

DEFINES=(--dart-define-from-file=.env.json)
modo="${1:-}"

case "$modo" in
  devices)
    flutter devices
    ;;
  run)
    id="${2:-}"
    [ -n "$id" ] || fallar "Indica el ID del iPhone (míralo con: bash scripts/build_ios.sh devices)."
    flutter run --release -d "$id" "${DEFINES[@]}"
    ;;
  build)
    flutter build ios --release "${DEFINES[@]}"
    ;;
  ipa)
    flutter build ipa --release "${DEFINES[@]}"
    echo "Listo: build/ios/ipa/"
    ;;
  *)
    sed -n '2,10p' "$0"
    exit 1
    ;;
esac
