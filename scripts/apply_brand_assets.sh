#!/usr/bin/env bash
# Copia la marca generada (build/brand/*.png) al icono y a la pantalla de
# arranque de iOS, Android y web. Para regenerar la marca:
#   flutter test tool/icon_gen/icon_gen_test.dart && bash scripts/apply_brand_assets.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=build/brand
[ -f "$SRC/icon_1024.png" ] || { echo "Falta $SRC/icon_1024.png: corre primero el generador."; exit 1; }

# Apple no admite transparencia en el icono: se pasa por JPEG y vuelve a PNG.
TMP=$(mktemp -d)
sips -s format jpeg "$SRC/icon_1024.png" --out "$TMP/icon.jpg" >/dev/null
sips -s format png "$TMP/icon.jpg" --out "$TMP/icon_1024.png" >/dev/null

resize() { sips -z "$2" "$2" "$TMP/icon_1024.png" --out "$1" >/dev/null; }

IOS=ios/Runner/Assets.xcassets/AppIcon.appiconset
for spec in 20x20@1x:20 20x20@2x:40 20x20@3x:60 29x29@1x:29 29x29@2x:58 29x29@3x:87 \
            40x40@1x:40 40x40@2x:80 40x40@3x:120 60x60@2x:120 60x60@3x:180 \
            76x76@1x:76 76x76@2x:152 83.5x83.5@2x:167 1024x1024@1x:1024; do
  resize "$IOS/Icon-App-${spec%%:*}.png" "${spec##*:}"
done

# Pantalla de arranque de iOS: el logo de 72 pt (el fondo lo pone el storyboard).
LAUNCH=ios/Runner/Assets.xcassets/LaunchImage.imageset
cp "$SRC/logo_72.png" "$LAUNCH/LaunchImage.png"
cp "$SRC/logo_144.png" "$LAUNCH/LaunchImage@2x.png"
cp "$SRC/logo_216.png" "$LAUNCH/LaunchImage@3x.png"

ANDROID=android/app/src/main/res
for spec in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  resize "$ANDROID/mipmap-${spec%%:*}/ic_launcher.png" "${spec##*:}"
done
# Logo para la pantalla de arranque de Android (72 dp fijos en el XML).
mkdir -p "$ANDROID/drawable-nodpi"
cp "$SRC/logo_216.png" "$ANDROID/drawable-nodpi/launch_mark.png"

resize web/favicon.png 32
resize web/icons/Icon-192.png 192
resize web/icons/Icon-512.png 512
resize web/icons/Icon-maskable-192.png 192
resize web/icons/Icon-maskable-512.png 512

rm -rf "$TMP"
echo "Marca aplicada a iOS, Android y web."
