#!/usr/bin/env bash
set -euo pipefail

# Inherit from Dockerfile defaults
export DATA_DIR="${DATA_DIR:-/workspace/a1111-data}"
export WEBUI_DIR="${WEBUI_DIR:-/opt/webui}"

# ---------- EXTENSIONS ----------
# Space/newline-separated Git URLs, e.g.:
# EXTENSIONS="https://github.com/Bing-su/adetailer https://github.com/Mikubill/sd-webui-controlnet https://github.com/civitai/sd-civitai-browser"
EXTENSIONS="${EXTENSIONS:-}"

install_or_update_ext() {
  local url="$1"
  [ -z "$url" ] && return 0
  local name="$(basename "${url%/}")"
  local dest="${DATA_DIR}/extensions/${name}"
  if [ -d "${dest}/.git" ]; then
    echo "[Ext] Updating ${name}"
    git -C "${dest}" fetch --depth=1 origin || true
    git -C "${dest}" reset --hard origin/HEAD || true
  else
    echo "[Ext] Cloning ${name}"
    git clone --depth=1 "$url" "$dest" || true
  fi
}

# ---------- MODELS ----------
# MODEL_URLS / LORA_URLS / VAE_URLS : space/newline-separated direct URLs
MODEL_URLS="${MODEL_URLS:-}"
LORA_URLS="${LORA_URLS:-}"
VAE_URLS="${VAE_URLS:-}"

dl_into() {
  local url="$1" dir="$2"
  [ -z "$url" ] && return 0
  mkdir -p "$dir"
  local fname="${dir}/$(basename "${url%%\?*}")"
  if [ -s "$fname" ]; then
    echo "[Model] Exists: $(basename "$fname")"
  else
    echo "[Model] Downloading: $url"
    (curl -L --fail "$url" -o "$fname" || wget -q -O "$fname" "$url") || {
      echo "[Model][WARN] failed: $url"
      rm -f "$fname"
    }
  fi
}

# ---------- Run once, then delegate ----------
# Ensure extension dir exists before starting A1111
mkdir -p "${DATA_DIR}/extensions"

# Install/update extensions
if [ -n "$EXTENSIONS" ]; then
  echo "[Ext] Processing extensions list"
  while read -r line; do
    install_or_update_ext "$line"
  done <<< "$(printf '%s\n' $EXTENSIONS)"
else
  echo "[Ext] No EXTENSIONS specified; skipping."
fi

# Models
for u in $MODEL_URLS; do dl_into "$u" "${DATA_DIR}/models/Stable-diffusion"; done
for u in $LORA_URLS;  do dl_into "$u" "${DATA_DIR}/models/Lora";              done
for u in $VAE_URLS;   do dl_into "$u" "${DATA_DIR}/models/VAE";               done

# Hand off to main startup
