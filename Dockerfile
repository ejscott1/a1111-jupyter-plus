FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VENV_DIR=/opt/venv \
    WEBUI_DIR=/opt/webui \
    DATA_DIR=/workspace/a1111-data \
    PORT=7860 \
    JUPYTER_PORT=8888

# Base OS deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip git wget curl ca-certificates \
    libgl1 libglib2.0-0 ffmpeg tzdata pciutils xxd && \
    rm -rf /var/lib/apt/lists/*

# Python venv
RUN python3 -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

# PyTorch (CUDA 12.1) + xFormers wheels
RUN pip install --upgrade pip setuptools wheel && \
    pip install --index-url https://download.pytorch.org/whl/cu121 \
        torch torchvision torchaudio && \
    pip install --index-url https://download.pytorch.org/whl/cu121 \
        xformers

# Quiet + stability
ENV PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True,max_split_size_mb:128" \
    HF_HUB_DISABLE_TELEMETRY=1 \
    TOKENIZERS_PARALLELISM=false

# Persistent data root
RUN mkdir -p $DATA_DIR

# Healthcheck (A1111)
HEALTHCHECK --interval=30s --timeout=60s --start-period=60s --retries=10 \
  CMD curl -fsSL "http://localhost:${PORT}/" >/dev/null || exit 1

# Startup scripts
COPY start.sh /opt/start.sh
COPY start-extra.sh /opt/start-extra.sh
RUN chmod +x /opt/start.sh /opt/start-extra.sh

# Defaults
ENV WEBUI_ARGS="--listen --port ${PORT} --api --data-dir ${DATA_DIR} --enable-insecure-extension-access --xformers" \
    ENABLE_JUPYTER=1 \
    JUPYTER_TOKEN= \
    JUPYTER_PORT=8888

EXPOSE 7860 8888
CMD ["/opt/start-extra.sh"]
