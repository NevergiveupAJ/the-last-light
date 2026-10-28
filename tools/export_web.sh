#!/bin/sh
# Exports the Web build into web/ for Cloudflare (Workers static assets).
# The .wasm is over Cloudflare's 25 MiB per-file limit, so it is stored gzipped and
# worker/index.js serves it with Content-Encoding: gzip.
# Usage: GODOT=/path/to/godot4.3 sh tools/export_web.sh
set -e
cd "$(dirname "$0")/.."
mkdir -p build/web
touch build/.gdignore
"${GODOT:-godot}" --headless --path . --export-release "Web" build/web/index.html
rm -rf web && mkdir web
# Keep Godot from importing the exported files, and keep that marker out of the upload.
touch web/.gdignore
printf ".gdignore\n.assetsignore\n" > web/.assetsignore
cp build/web/* web/
rm -f web/*.import
gzip -9 -c build/web/index.wasm > web/index.wasm.gz
rm web/index.wasm
ls -la web
