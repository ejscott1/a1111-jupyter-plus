# A1111 + Jupyter Plus (RunPod + GHCR)

Independent image that runs AUTOMATIC1111 Stable Diffusion WebUI with **JupyterLab**, **xFormers**, and an **auto installer** for selected **extensions** and **models** at startup.  
All data persists in `/workspace/a1111-data`.

## 📦 Image
ghcr.io/ejscott1/a1111-jupyter-plus:latest

## 🚀 Quick Start (RunPod)
- **Image:** ghcr.io/ejscott1/a1111-jupyter-plus:latest  
- **GPU:** A4500 / A5000 (balanced) or A40 / RTX 4090 (fastest for SDXL)  
- **Persistent Volume:** mount at `/workspace` (50–100GB recommended)  
- **Expose Ports:** 7860 (A1111), 8888 (Jupyter)  
- **Environment Variables (recommended defaults):**
  ```
  WEBUI_ARGS=--listen --port 7860 --api --data-dir /workspace/a1111-data --enable-insecure-extension-access --xformers
  ENABLE_JUPYTER=1
  JUPYTER_PORT=8888
  EXTENSIONS=https://github.com/Bing-su/adetailer https://github.com/Mikubill/sd-webui-controlnet https://github.com/civitai/sd-civitai-browser https://github.com/Coyote-A/ultimate-upscale-for-automatic1111
  MODEL_URLS=https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
  ```

➡️ After launch:  
- **HTTP 8888** → JupyterLab (opens directly).  
- **HTTP 7860** → A1111 WebUI (`--xformers` enabled).  
- Preinstalled extensions appear under **Extensions → Installed**.  
- Models are ready in `/workspace/a1111-data/models/Stable-diffusion/`.

## 📂 Paths
- **Checkpoints:** `/workspace/a1111-data/models/Stable-diffusion/`  
- **LoRA:** `/workspace/a1111-data/models/Lora/`  
- **VAE:** `/workspace/a1111-data/models/VAE/`  
- **Extensions:** `/workspace/a1111-data/extensions/` (symlinked into `/opt/webui/extensions`)  
- **Outputs:** `/workspace/a1111-data/outputs/`  
- **Configs (SD 1.5):** `/workspace/a1111-data/configs/v1-inference.yaml`

## 📝 Notes
- CUDA 12.1 with Torch + xFormers (cu121 wheels).  
- Auto symlink repair ensures all A1111 paths point to persistent storage.  
- SD 1.5 YAML auto-downloaded on first run; SDXL needs no YAML.  
- Extensions/models install is idempotent — existing files are reused.

## 👩‍💻 Developer Notes
- Change `EXTENSIONS` to add/remove GitHub extension repos.  
- Add `MODEL_URLS`, `LORA_URLS`, `VAE_URLS` to auto-download other models.  
- Extensions and models are downloaded/updated at pod startup (not baked in).
