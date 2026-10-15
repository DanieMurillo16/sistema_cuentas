#!/usr/bin/env bash
# Compila la web de la app para producción.
#
# Uso:
#   bash scripts/build_web.sh --dart-define=API_BASE_URL=...
#   (Wasm va activado por defecto; el mismo build sirve a los navegadores sin
#   WasmGC con JavaScript. Android e iOS compilan nativo con build_ios.sh/flutter build.)
#
# La URL de la API sale de .env.json (copia .env.json.ejemplo; git lo ignora).
# También se puede pasar --dart-define=API_BASE_URL=... o
# --dart-define-from-file=otro.json, y entonces .env.json no se usa.
#
# Se ejecuta con bash a propósito: ~/.zshrc define una función `flutter` que
# añade --no-tree-shake-icons a `flutter build web`, y bash no la hereda.
#
# El recorte de fuentes queda activo. Cada despliegue debe subir build/web
# entero y purgar el CDN: mezclar el JavaScript nuevo con una fuente de otro
# build puede dejar iconos en blanco.
set -euo pipefail
cd "$(dirname "$0")/.."

output_dir=build/web
expects_output=false
has_api_url=false
has_wasm=false
for argument in "$@"; do
  if $expects_output; then
    output_dir=$argument
    expects_output=false
    continue
  fi
  case "$argument" in
    --no-tree-shake-icons)
      echo "Error: no desactives el recorte de iconos en el build de producción." >&2
      exit 1
      ;;
    --output|-o) expects_output=true ;;
    --output=*|-o=*) output_dir=${argument#*=} ;;
    --wasm) has_wasm=true ;;
    --dart-define=API_BASE_URL=?*|--dart-define-from-file=?*) has_api_url=true ;;
  esac
done

extra_args=()
if ! $has_api_url && [[ -f .env.json ]]; then
  if ! grep -q '"API_BASE_URL": *"[^"]\+"' .env.json; then
    echo "Error: .env.json no tiene API_BASE_URL." >&2
    exit 1
  fi
  extra_args=(--dart-define-from-file=.env.json)
  has_api_url=true
fi

# Sin API_BASE_URL la app compila, pero el login responde "Configura
# API_BASE_URL" en el navegador del cliente.
if ! $has_api_url; then
  echo "Error: falta la URL de la API. Crea .env.json (ver .env.json.ejemplo) o pasa --dart-define=API_BASE_URL=..." >&2
  exit 1
fi
if ! command -v brotli >/dev/null 2>&1; then
  echo "Error: falta brotli (brew install brotli). No subas este build." >&2
  exit 1
fi

# Flutter no borra v/ del build anterior; solo debe subirse la versión nueva.
rm -rf "$output_dir/v"

# Wasm por defecto: Chrome/Edge usan skwasm y el resto cae al JS del mismo
# build, así que olvidar la bandera no deja la web sin la optimización.
wasm_args=()
if ! $has_wasm; then
  wasm_args=(--wasm)
fi

flutter build web --release --tree-shake-icons ${wasm_args[@]+"${wasm_args[@]}"} ${extra_args[@]+"${extra_args[@]}"} "$@"

# Flutter copia todo lo que hay en web/, incluidos los .DS_Store que macOS deja
# en las carpetas: llegarían al servidor y se podrían descargar.
find "$output_dir" -name .DS_Store -delete
if [[ -n "$(find "$output_dir" -name .DS_Store -print -quit)" ]]; then
  echo "Error: quedó un .DS_Store en $output_dir. No subas este build." >&2
  exit 1
fi

# Se revisa el resultado: una compilación hecha desde zsh restaura las fuentes
# completas aunque el comando parezca correcto.
verify_font() {
  local font_path=$1
  local maximum_bytes=$2
  if [[ ! -f "$font_path" ]]; then
    echo "Error: falta la fuente $font_path. No subas este build." >&2
    exit 1
  fi
  local actual_bytes
  actual_bytes=$(wc -c < "$font_path" | tr -d ' ')
  if (( actual_bytes > maximum_bytes )); then
    echo "Error: $font_path tiene $actual_bytes bytes; revisa el recorte de iconos antes de subir." >&2
    exit 1
  fi
  echo "Fuente verificada: $font_path ($actual_bytes bytes)."
}

# Presupuesto amplio para nuevos iconos; las fuentes completas pesan 1,6 MB y
# 258 KB.
verify_font "$output_dir/assets/fonts/MaterialIcons-Regular.otf" 262144
verify_font "$output_dir/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf" 32768

# El CDN comprime al vuelo con calidad baja; con Brotli 11 main.dart.js pesa
# bastante menos. La negociación por Accept-Encoding con RewriteRule comprimía
# dos veces en LiteSpeed, así que el bootstrap pide la variante Brotli por su
# nombre, en una ruta versionada que existe como archivo real. Debe terminar en
# .js: el cargador de Flutter rechaza cualquier otro nombre.
bootstrap="$output_dir/flutter_bootstrap.js"
version=$(sed -n 's/^ *var version = "\([0-9]*\)".*/\1/p' "$bootstrap")
if [[ -z "$version" ]]; then
  echo "Error: no encontré la versión del build en $bootstrap." >&2
  exit 1
fi
dest="$output_dir/v/$version"
mkdir -p "$dest"

compress_entry() {
  local source=$1
  local target=$2
  brotli --force --quality=11 --output="$target" "$source"
  if ! brotli --decompress --stdout "$target" | cmp -s "$source" -; then
    echo "Error: $target no descomprime igual que $source." >&2
    exit 1
  fi
}

replace_entry() {
  local current=$1
  local replacement=$2
  if [[ $(grep -cF "$current" "$bootstrap") != 1 ]]; then
    echo "Error: no encontré «$current» en $bootstrap." >&2
    exit 1
  fi
  sed -i '' "s#$current#$replacement#" "$bootstrap"
}

main_br="$dest/main.dart.br.js"
compress_entry "$output_dir/main.dart.js" "$main_br"
replace_entry "build.mainJsPath = 'v/' + version + '/' + build.mainJsPath;" \
  "build.mainJsPath = 'v/' + version + '/main.dart.br.js';"
echo "Entrypoint Brotli verificado: v/$version/main.dart.br.js ($(wc -c < "$main_br" | tr -d ' ') bytes)."

# Con --wasm, Chrome/Edge bajan main.dart.wasm y Safari/Firefox siguen con
# main.dart.br.js. El Wasm va igual: Brotli 11, pedido por su nombre.
if grep -q '"compileTarget":"dart2wasm"' "$bootstrap"; then
  wasm_br="$dest/main.dart.br.wasm"
  compress_entry "$output_dir/main.dart.wasm" "$wasm_br"
  replace_entry "build.mainWasmPath = 'v/' + version + '/' + build.mainWasmPath;" \
    "build.mainWasmPath = 'v/' + version + '/main.dart.br.wasm';"
  echo "Entrypoint Wasm Brotli verificado: v/$version/main.dart.br.wasm ($(wc -c < "$wasm_br" | tr -d ' ') bytes)."

  # Con la página aislada (COOP + COEP) skwasm rasteriza en un web worker y
  # no en el hilo principal. credentialless deja cargar recursos de otros
  # dominios (CanvasKit de gstatic, la API) sin pedirles CORP.
  cat >> "$output_dir/.htaccess" <<'HTACCESS'

<IfModule mod_headers.c>
  Header always set Cross-Origin-Opener-Policy "same-origin"
  Header always set Cross-Origin-Embedder-Policy "credentialless"
</IfModule>
HTACCESS
  echo "Página aislada (COOP/COEP) añadida a $output_dir/.htaccess."
fi

# flutter.js trae un comentario sourceMappingURL hacia un archivo que el build
# no genera: Lighthouse lo reporta como mapa de origen inválido.
sed -i '' '/^\/\/# sourceMappingURL=flutter\.js\.map$/d' "$bootstrap"
if grep -q 'sourceMappingURL' "$bootstrap"; then
  echo "Error: quedó un sourceMappingURL en $bootstrap." >&2
  exit 1
fi

# Todo lo que el bootstrap pide bajo v/<versión>/ queda ahí como archivo real:
# las reescrituras v/... → raíz fallaron en LiteSpeed.
mv "$output_dir/assets" "$dest/assets"
for versioned in "$output_dir"/main.dart.js_*.part.js "$output_dir/main.dart.mjs"; do
  if [[ -f "$versioned" ]]; then
    mv "$versioned" "$dest/"
  fi
done
if [[ ! -f "$dest/assets/FontManifest.json" ]]; then
  echo "Error: falta $dest/assets/FontManifest.json." >&2
  exit 1
fi

echo
echo "Listo: sube el CONTENIDO de $output_dir completo, incluidos los archivos ocultos (.htaccess)."
