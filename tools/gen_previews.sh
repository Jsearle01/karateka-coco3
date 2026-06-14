#!/usr/bin/env bash
# gen_previews.sh — regenerate CoCo3 sprite previews into build/preview/,
# mirroring the content/<category>/<dir>/ folder layout (2026-06-14 restructure).
# Output: build/preview/<category>/<dir>.png  (build/ is gitignored).
set -e
cd "$(dirname "$0")/.."

OUT=build/preview
SCALE="${1:-6}"
rm -rf "$OUT"

n=0
for f in content/*/*/converted.s; do
    [ -f "$f" ] || continue
    cat="$(basename "$(dirname "$(dirname "$f")")")"   # category folder
    dir="$(basename "$(dirname "$f")")"                # sprite dir name
    mkdir -p "$OUT/$cat"
    if python tools/sprite_visualize.py --source "$f" --output "$OUT/$cat/$dir.png" --scale "$SCALE" >/dev/null 2>&1; then
        n=$((n + 1))
    else
        echo "  FAILED: $f"
    fi
done
echo "generated $n previews under $OUT/<category>/ (scale ${SCALE}x)"
