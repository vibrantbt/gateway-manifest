#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./update.sh --env <dev|prod> --set <KEY=VALUE> [--set <KEY=VALUE> ...]

Examples:
  ./update.sh --env dev \
    --set VBT_GATEWAYOS_IMAGE=harbor-dev.vibrantbt.net/gateway/gatewayos:2026.01.23-deadbeef

Notes:
- This repo is intended to be public. Do not store secrets here.
- "dev" and "prod" are separate manifests.
EOF
}

ENV_NAME=""
SETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_NAME="${2:-}"; shift 2 ;;
    --set)
      SETS+=("${2:-}"); shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${ENV_NAME}" ]] || [[ "${ENV_NAME}" != "dev" && "${ENV_NAME}" != "prod" ]]; then
  echo "ERROR: --env must be dev or prod" >&2
  usage
  exit 2
fi

if [[ ${#SETS[@]} -eq 0 ]]; then
  echo "ERROR: at least one --set KEY=VALUE is required" >&2
  usage
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_FILE="${SCRIPT_DIR}/${ENV_NAME}/images.env"

if [[ ! -f "${TARGET_FILE}" ]]; then
  echo "ERROR: manifest file not found: ${TARGET_FILE}" >&2
  exit 1
fi

python3 - <<'PY'
import os
import sys

target = os.environ["TARGET_FILE"]
updates = os.environ["UPDATES"].split("\n")
updates = [u for u in updates if u.strip()]

kv = {}
for u in updates:
  if "=" not in u:
    raise SystemExit(f"invalid --set (expected KEY=VALUE): {u}")
  k, v = u.split("=", 1)
  kv[k.strip()] = v.strip()

with open(target, "r", encoding="utf-8") as f:
  lines = f.read().splitlines()

out = []
seen = set()
for line in lines:
  raw = line
  s = line.strip()
  if not s or s.startswith("#") or "=" not in line:
    out.append(raw)
    continue

  k, rest = line.split("=", 1)
  k_stripped = k.strip()
  if k_stripped in kv:
    out.append(f"{k_stripped}={kv[k_stripped]}")
    seen.add(k_stripped)
  else:
    out.append(raw)

# Append missing keys at end
missing = [k for k in kv.keys() if k not in seen]
if missing:
  out.append("")
  out.append("# Added by update.sh")
  for k in missing:
    out.append(f"{k}={kv[k]}")

with open(target, "w", encoding="utf-8") as f:
  f.write("\n".join(out) + "\n")
PY