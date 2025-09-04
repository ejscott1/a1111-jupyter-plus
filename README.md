# A1111 + Jupyter (Extensions + Models)

Independent image that runs AUTOMATIC1111 Stable Diffusion WebUI with **JupyterLab**, **xFormers**, and an **auto installer** for selected **extensions** and **1–2 models** at startup. All data persists in `/workspace/a1111-data`.

## 🚀 Quick Start (RunPod)
- **Image:** ghcr.io/ejscott1/a1111-jupyter-plus:latest  
- **Ports:** 7860 (A1111), 8888 (Jupyter)  
- **Volume:** mount at `/workspace` (50–100GB recommended)  
- **Env (examples):**
  ```
  # A1111 defaults (already set in image)
  WEBUI_ARGS=--listen --port 7860 --api --data-dir /workspace/a1111-data --enable-insecure-extension-access --xformers

  # Enable Jupyter (no token)
  ENABLE_JUPYTER=1
  JUPYTER_PORT=8888

  # Extensions to pre-install (space/newline separated Git URLs)
  EXTENSIONS=https://github.com/Bing-su/adetailer https://github.com/Mikubill/sd-webui-controlnet https://github.com/civitai/sd-civitai-browser

  # Optional: 1–2 models to prefetch (direct .safetensors/.ckpt links)
  # Example (SD 1.5 EMA-only):
  MODEL_URLS=https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

  # Optional: LoRAs / VAEs
  # LORA_URLS=
  # VAE_URLS=
  ```

➡️ After launch:
1. **HTTP 8888** → JupyterLab (opens directly).  
2. **HTTP 7860** → A1111 WebUI (`--xformers` enabled).  
3. Extensions live under `/workspace/a1111-data/extensions` (linked into WebUI).  
4. Models appear under `/workspace/a1111-data/models/...`.

## 📂 Paths
- Checkpoints: `/workspace/a1111-data/models/Stable-diffusion/`  
- LoRA: `/workspace/a1111-data/models/Lora/`  
- VAE: `/workspace/a1111-data/models/VAE/`  
- Extensions: `/workspace/a1111-data/extensions/` (symlinked to `/opt/webui/extensions`)  
- Outputs: `/workspace/a1111-data/outputs/`  
- Configs (SD 1.5): `/workspace/a1111-data/configs/v1-inference.yaml`

## 📝 Notes
- CUDA 12.1 base with Torch/xFormers cu121 wheels (fast + compatible).  
- Auto symlink repair ensures all WebUI paths write to the persistent volume.  
- SD 1.5 YAML is auto-downloaded on first run; SDXL needs no YAML.  
- Extensions/models install is idempotent — existing files are reused.
