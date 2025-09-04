#!/usr/bin/env bash
set -euo pipefail

# Inherit defaults
export DATA_DIR="${DATA_DIR:-/workspace/a1111-data}"
export WEBUI_DIR="${WEBUI_DIR:-/opt/webui}"
export EXTENSIONS="${EXTENSIONS:-}"
export MODEL_URLS="${MODEL_URLS:-}"
export LORA_URLS="${LORA_URLS:-}"
export VAE_URLS="${VAE_URLS:-}"

BOOTLOG="${DATA_DIR}/logs/bootstrap.log"
mkdir -p "${DATA_DIR}/logs"
echo "[BOOT] $(date -Is) starting bootstrap" > "$BOOTLOG"

# ---------- helpers ----------
normalize_git_url() {
  # ensure https://... and .git suffix
  local u="$1"
  [[ -z "$u" ]] && { echo ""; return; }
  if [[ "$u" =~ ^git@ || "$u" =~ ^ssh:// ]]; then
    echo "$u"
    return
  fi
  [[ "$u" != https://* ]] && u="https://$u"
  [[ "$u" != *.git ]] && u="${u%/}.git"
  echo "$u"
}

clone_or_update() {
  local url="$1"; local dest="$2"; local name="$3"
  # 20s connect timeout, 600s overall, shallow
  if [ -d "${dest}/.git" ]; then
    echo "[Ext] Updating ${name}" | tee -a "$BOOTLOG"
    (git -C "${dest}" fetch --depth=1 origin || true)
    (git -C "${dest}" reset --hard origin/HEAD || true)
  else
    echo "[Ext] Cloning ${name} from ${url}" | tee -a "$BOOTLOG"
    GIT_ASKPASS=/bin/true git clone --depth=1 "${url}" "${dest}" || {
      echo "[Ext][WARN] Failed to clone ${name}" | tee -a "$BOOTLOG"
    }
  fi
}

dl_into() {
  # $1=url  $2=dir
  local url="$1" dir="$2"
  [ -z "$url" ] && return 0
  mkdir -p "$dir"
  local fname="${dir}/$(basename "${url%%\?*}")"
  if [ -s "$fname" ]; then
    echo "[Model] Exists: $(basename "$fname")" | tee -a "$BOOTLOG"
  else
    echo "[Model] Downloading: $url" | tee -a "$BOOTLOG"
    # 30s connect timeout, resume supported via curl --continue-at -
    if command -v curl >/dev/null 2>&1; then
      curl -L --fail --retry 3 --retry-delay 3 --connect-timeout 30 --continue-at - -o "$fname" "$url" \
        || { echo "[Model][WARN] curl failed: $url" | tee -a "$BOOTLOG"; rm -f "$fname"; }
    else
      wget --tries=3 --timeout=600 -O "$fname" "$url" \
        || { echo "[Model][WARN] wget failed: $url" | tee -a "$BOOTLOG"; rm -f "$fname"; }
    fi
  fi
}

# ---------- ensure extensions dir symlinked to persistent ----------
mkdir -p "${DATA_DIR}/extensions"
rm -rf "${WEBUI_DIR}/extensions" 2>/dev/null || true
ln -s "${DATA_DIR}/extensions" "${WEBUI_DIR}/extensions"

# ---------- process extensions (fast, before starting servers) ----------
if [ -n "$EXTENSIONS" ]; then
  echo "[Ext] Processing EXTENSIONS..." | tee -a "$BOOTLOG"
  # split on whitespace; normalize each to https://... .git
  for raw in $EXTENSIONS; do
    url="$(normalize_git_url "$raw")"
    [ -z "$url" ] && continue
    name="$(basename "${url%.*}")"
    dest="${DATA_DIR}/extensions/${name}"
    clone_or_update "$url" "$dest" "$name"
  done
else
  echo "[Ext] No EXTENSIONS specified; skipping." | tee -a "$BOOTLOG"
fi

# ---------- kick off model downloads in background (do not block ports) ----------
(
  echo "[Model] Background downloads starting..." | tee -a "$BOOTLOG"
  for u in $MODEL_URLS; do dl_into "$u" "${DATA_DIR}/models/Stable-diffusion"; done
  for u in $LORA_URLS;  do dl_into "$u" "${DATA_DIR}/models/Lora";              done
  for u in $VAE_URLS;   do dl_into "$u" "${DATA_DIR}/models/VAE";               done
  echo "[Model] Background downloads finished." | tee -a "$BOOTLOG"
) & disown

# ---------- hand off to main startup (starts Jupyter + A1111) ----------
exec /opt/start.sh
