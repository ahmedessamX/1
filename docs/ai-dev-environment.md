# AI Dev Environment — Container Guide

## Why Containerise Your AI Workspace?

Running PyTorch, TensorFlow, CUDA, and HuggingFace libraries directly on Windows leads to:

- **CUDA version conflicts** between frameworks (PyTorch needs CUDA 12.1, an older project needs 11.8)
- **Broken conda environments** after a system update changes a DLL
- **Long, fragile PATH strings** with competing Python installations
- **"Works on my machine" problems** when sharing code

A Docker container gives each project its own isolated CUDA + Python + library stack, with **GPU passthrough** through the NVIDIA Container Toolkit.

---

## Prerequisites (host side only)

| Requirement | Notes |
|-------------|-------|
| Windows 11 (or 10 21H2+) | Required for WSL2 GPU passthrough |
| NVIDIA GPU | GeForce, Quadro, or RTX series |
| Latest NVIDIA driver | ≥ 526.x; install from [nvidia.com](https://www.nvidia.com/Download/index.aspx) — **no CUDA toolkit on the host** |
| Docker Desktop 4.x | Enable WSL2 backend + "Use GPU" in settings |
| VS Code + Dev Containers extension | For editing inside the container |

---

## Repository Layout

```
docker/ai-dev/
├── Dockerfile              # Production-ready AI dev image
├── docker-compose.yml      # Orchestrates the dev stack
├── requirements.txt        # Python packages (edit as needed)
└── .env.example            # Environment variable template
```

---

## Quick Start

```bash
# 1. Copy the env template
cp docker/ai-dev/.env.example docker/ai-dev/.env
# Edit .env — add HuggingFace token, API keys, etc.

# 2. Build and start the stack
cd docker/ai-dev
docker compose up -d

# 3. Verify GPU access
docker exec -it ai-dev nvidia-smi

# 4. Open JupyterLab in your browser
#    → http://localhost:8888  (token is in docker compose logs)

# 5. (Optional) Attach VS Code to the container
#    Command Palette → Dev Containers: Attach to Running Container → ai-dev
```

---

## Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```env
# HuggingFace
HF_TOKEN=hf_...
HF_HOME=/workspace/.cache/huggingface

# OpenAI / other APIs
OPENAI_API_KEY=sk-...

# Weights & Biases (optional)
WANDB_API_KEY=...
WANDB_PROJECT=my-project

# Jupyter
JUPYTER_TOKEN=change_me_please
```

**Never commit `.env` to git.** It is listed in `.gitignore`.

---

## Working with the Container

### Running a training script
```bash
docker exec -it ai-dev python /workspace/train.py
```

### Opening a shell inside the container
```bash
docker exec -it ai-dev bash
```

### Mounting additional data directories
Edit `docker-compose.yml` and add a volume under `ai-dev → volumes`:
```yaml
- D:/datasets:/workspace/datasets:ro
```

### Installing additional packages temporarily
```bash
docker exec -it ai-dev pip install einops
```

For permanent additions, add to `requirements.txt` and rebuild:
```bash
docker compose build --no-cache && docker compose up -d
```

---

## CUDA Version Matrix

The `Dockerfile` defaults to **CUDA 12.4 + cuDNN 9**. If your project requires a different version, change the `FROM` line:

| CUDA | cuDNN | PyTorch | Base image tag |
|------|-------|---------|----------------|
| 12.4 | 9 | 2.3+ | `nvidia/cuda:12.4.1-cudnn9-devel-ubuntu22.04` |
| 12.1 | 8 | 2.1–2.2 | `nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04` |
| 11.8 | 8 | 1.13–2.0 | `nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04` |

> For multiple CUDA versions simultaneously, run separate Docker Compose projects in separate directories.

---

## Saving and Sharing Your Environment

### Export the image
```bash
docker save ai-dev:latest | gzip > ai-dev-backup.tar.gz
```

### Restore on a new machine
```bash
docker load < ai-dev-backup.tar.gz
```

### Share via Docker Hub / GitHub Container Registry
```bash
docker tag ai-dev:latest ghcr.io/<your-user>/ai-dev:latest
docker push ghcr.io/<your-user>/ai-dev:latest
```

### Commit conda environment from inside the container
```bash
docker exec -it ai-dev conda env export > docker/ai-dev/conda_env.yml
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `nvidia-smi` not found in container | Ensure `--gpus all` flag or `deploy.resources` in compose; check host driver version |
| `CUDA out of memory` | Reduce batch size; verify no other process holds GPU memory: `nvidia-smi` on host |
| Container exits immediately | Check logs: `docker compose logs ai-dev` |
| Can't connect to JupyterLab | Verify port 8888 is not used: `netstat -an | findstr 8888` |
| Slow file I/O on mounted Windows paths | Move working files to a WSL2 path (`/workspace`); Windows mounts (`/mnt/c`) are slow |
| `torch.cuda.is_available()` returns False | Rebuild with correct CUDA base image; verify Docker Desktop GPU toggle is on |
