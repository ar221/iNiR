#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
runtime_root="$(cd -- "$script_dir/.." && pwd)"
launcher="${INIR_LAUNCHER_PATH:-$runtime_root/scripts/inir}"
out_dir="${INIR_PERF_DIR:-$runtime_root/.perf}"
stamp="$(date +%Y%m%d-%H%M%S)"
run_dir="$out_dir/$stamp"

mkdir -p "$run_dir"

echo "== perf smoke: $stamp =="
echo "output: $run_dir"

if command -v hyperfine >/dev/null 2>&1; then
  hyperfine \
    --warmup 1 \
    --runs "${INIR_PERF_HYPERFINE_RUNS:-5}" \
    --export-json "$run_dir/hyperfine-startup.json" \
    --command-name "inir-status" \
    "bash '$launcher' status >/dev/null" \
    --command-name "inir-path" \
    "bash '$launcher' path >/dev/null"
else
  echo "WARN: hyperfine not found; skipping startup timing"
fi

if command -v pidstat >/dev/null 2>&1; then
  set +e
  pidstat -r -u -w 1 5 >"$run_dir/pidstat.txt" 2>&1
  set -e
else
  echo "WARN: pidstat not found; skipping CPU/wakeup sample"
fi

set +e
bash "$launcher" logs --full >"$run_dir/logs-full.txt" 2>&1
set -e

if command -v rg >/dev/null 2>&1; then
  rg -n "error|ReferenceError|TypeError|binding loop" "$run_dir/logs-full.txt" >"$run_dir/logs-errors.txt" || true
else
  echo "rg not found" >"$run_dir/logs-errors.txt"
fi

echo "done: $run_dir"
