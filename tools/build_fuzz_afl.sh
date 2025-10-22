#!/usr/bin/env bash
set -euo pipefail
if ! command -v afl-gcc >/dev/null && ! command -v afl-cc >/dev/null; then
  echo "AFL++ not found (need afl-gcc or afl-cc)"; exit 1
fi
AFL=${AFL:-$(command -v afl-gcc || command -v afl-cc)}
SRC="${1:-fuzz/fuzz_mbr.c}"
OUT="${2:-build/fuzz_mbr_afl}"
mkdir -p "$(dirname "$OUT")"
$AFL -O2 -g -fsanitize=address,undefined -o "$OUT" "$SRC"
echo "Built AFL-instrumented fuzzer at $OUT"
