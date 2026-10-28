#!/bin/sh
# Descarga o actualiza en ./site las versiones web (WebAssembly) oficiales de las apps ArtCraft.
# Pensado para ejecutarse en un contenedor alpine:  docker compose run --rm actualizar
# Solo baja una app cuando cambia su versión. Si una descarga falla, la versión anterior se queda.
set -eu
command -v curl >/dev/null && command -v unzip >/dev/null || apk add --no-cache curl unzip >/dev/null
cd "${CRAFT_DIR:-/w}"
mkdir -p site/icons
APPS="${CRAFT_APPS:-photocraft vectorcraft designcraft pdfcraft lightcraft filmcraft effectcraft soundcraft figcraft cadcraft wordcraft gridcraft deckcraft}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
json="{"
for a in $APPS; do
  tag=$(curl -sSI "https://github.com/storytold/$a/releases/latest" | grep -i '^location:' | sed 's#.*/tag/##' | tr -d '\r\n ')
  v=${tag#v}
  cur=""; [ -f "site/$a/.version" ] && cur=$(cat "site/$a/.version")
  if [ -z "$v" ]; then
    echo "$a: no encuentro la última versión; se queda la actual (${cur:-ninguna})"; v=$cur
  elif [ "$cur" != "$v" ]; then
    echo "$a: ${cur:-nueva} -> $v"
    if curl -fsSL -o "$TMP/$a.zip" "https://github.com/storytold/$a/releases/download/$tag/$a-web-$v.zip" \
       && mkdir -p "$TMP/$a" && unzip -q "$TMP/$a.zip" -d "$TMP/$a" && [ -f "$TMP/$a/$a-web-$v/index.html" ]; then
      rm -rf "site/$a.new"; mv "$TMP/$a/$a-web-$v" "site/$a.new"
      echo "$v" > "site/$a.new/.version"
      rm -rf "site/$a.old"; [ -d "site/$a" ] && mv "site/$a" "site/$a.old"
      mv "site/$a.new" "site/$a"; rm -rf "site/$a.old"
    else
      echo "$a: la descarga falló; se queda la actual (${cur:-ninguna})"; v=$cur
    fi
  else
    echo "$a: $v al día"
  fi
  [ -s "site/icons/$a.png" ] || for s in 128x128 64x64; do
    curl -fsSL -o "site/icons/$a.png" \
      "https://raw.githubusercontent.com/storytold/$a/main/assets/app-icon/hicolor/$s/apps/ai.storyteller.$a.png" && break
  done || true
done
# Índice de versiones con todo lo instalado (no solo lo actualizado ahora)
json="{"
for d in site/*/.version; do [ -f "$d" ] || continue; a=${d#site/}; a=${a%/.version}; json="$json\"$a\":\"$(cat "$d")\","; done
echo "${json%,}}" > site/versiones.json
chmod -R a+rX site
echo "Hecho."
