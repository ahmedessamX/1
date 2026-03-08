# New System Architecture

## Overview

This document describes the recommended architecture for your new Windows system after a clean install. It is based on lessons learned from your existing setup — specifically the dependency conflicts, PATH pollution, and unstable AI dev environment noted during the analysis phase.

---

## Core Principles

| Principle | Rationale |
|-----------|-----------|
| **Isolate AI workloads in containers** | Eliminates CUDA/Python version conflicts between projects |
| **Single package manager per domain** | Reduces conflicts; use winget for GUI apps, Scoop for CLI tools |
| **Minimal global Python** | Only conda base; all project deps live in named environments or containers |
| **WSL2 as the Linux layer** | Better than dual-boot; Docker runs inside it natively |
| **Declarative configuration** | Every setup step is a script or YAML — reproducible from scratch |

---

## Layer Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      Windows Host                        │
│                                                          │
│  ┌──────────────────┐   ┌──────────────────────────────┐ │
│  │  Native Windows  │   │          WSL2                │ │
│  │  Applications    │   │  ┌────────────────────────┐  │ │
│  │                  │   │  │    Docker Engine       │  │ │
│  │  • GUI apps      │   │  │                        │  │ │
│  │  • Office        │   │  │  ┌──────────────────┐  │  │ │
│  │  • Browsers      │   │  │  │  ai-dev container│  │  │ │
│  │  • Video/audio   │   │  │  │  (CUDA + Python) │  │  │ │
│  └──────────────────┘   │  │  └──────────────────┘  │  │ │
│                         │  │  ┌──────────────────┐  │  │ │
│  ┌──────────────────┐   │  │  │  data container  │  │  │ │
│  │  Windows Tooling │   │  │  │  (Jupyter/DB)    │  │  │ │
│  │                  │   │  │  └──────────────────┘  │  │ │
│  │  • VS Code       │   │  │  ┌──────────────────┐  │  │ │
│  │  • Git           │   │  │  │  web-dev container│  │  │ │
│  │  • Docker Desktop│   │  │  │  (Node/React)    │  │  │ │
│  └──────────────────┘   │  │  └──────────────────┘  │  │ │
│                         │  └────────────────────────┘  │ │
│                         └──────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## Windows Host Layer

### Package Management Strategy

| Tool | Use for | Why |
|------|---------|-----|
| **winget** | GUI applications, major tools | Ships with Windows; official |
| **Scoop** | CLI developer tools (git, curl, fzf) | No admin required, no PATH pollution |
| **Chocolatey** | Legacy / unavailable-in-winget packages only | Avoid as first choice |

**Avoid:**
- Installing Python directly on the Windows host (use conda or containers)
- Global `pip install` outside a virtual environment
- Multiple Node.js versions on the host (use `nvm-windows` or containers)

### Essential Windows Applications (Baseline)

```
# Run once after clean install:
winget import -i packages/winget-packages.json --accept-package-agreements
```

Recommended baseline:
- **Docker Desktop** (with WSL2 backend)
- **VS Code** (with Remote – Containers extension)
- **Git for Windows**
- **Windows Terminal**
- **Miniconda** (for the host conda base only)
- **PowerToys**

---

## WSL2 Layer

WSL2 acts as a lightweight Linux environment and Docker host.

### Setup
```powershell
wsl --install           # enables WSL2 + installs Ubuntu
wsl --set-default-version 2
```

### WSL2 Resource Limits

Create `%USERPROFILE%\.wslconfig`:
```ini
[wsl2]
memory=12GB          # adjust to your RAM (leave 4 GB for Windows)
processors=6         # leave 2 cores for Windows
swap=4GB
localhostForwarding=true
```

---

## Docker / Containerisation Layer

This is the **key architectural change** from your old setup. Instead of installing CUDA, Python, and AI frameworks directly on the host, each project or domain gets its own container.

### Why containers for AI dev?

- **Version isolation**: PyTorch 2.x + CUDA 12 in container A, TensorFlow + CUDA 11 in container B — zero conflict.
- **Reproducibility**: Share a `Dockerfile` instead of a lengthy "install guide".
- **Clean host**: The Windows host only needs Docker Desktop; no CUDA toolkit on the host itself (NVIDIA GPU passthrough works via the NVIDIA Container Toolkit).
- **Easy reset**: Destroy and rebuild a broken environment in minutes.

### GPU Passthrough (NVIDIA)

You only need the **host GPU driver** (latest Game Ready or Studio driver from nvidia.com). The CUDA toolkit lives *inside* the container.

```powershell
# Verify GPU is accessible from Docker
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### Container Layout (Recommended)

| Container | Image base | Purpose |
|-----------|-----------|---------|
| `ai-dev` | `nvidia/cuda:12.x-cudnn-devel-ubuntu22.04` | PyTorch, HuggingFace, LLMs |
| `jupyter` | `jupyter/scipy-notebook` | Exploratory analysis |
| `web-dev` | `node:lts-alpine` | React / Next.js projects |
| `db` | `postgres:16-alpine` | Shared database |

See `docker/ai-dev/` for the ready-to-use AI dev container.

---

## AI Dev Environment

### Old approach (problematic)
```
Host Python ←→ conda base ←→ conda envs ←→ system pip
       ↑ conflicts with ↓
CUDA 11 ←→ CUDA 12 (multiple toolkit installs)
```

### New approach (containerised)
```
Windows Host
  └─ Docker Desktop (WSL2 backend)
       └─ ai-dev container
            ├─ CUDA 12.x (only copy; inside container)
            ├─ cuDNN (inside container)
            ├─ Python 3.11 managed by uv/conda (inside container)
            ├─ PyTorch / TensorFlow / JAX
            ├─ HuggingFace Transformers
            └─ Jupyter Lab (port 8888)
```

VS Code connects to the container via the **Dev Containers** extension — you edit files on your host but execute inside the container.

---

## Python / Conda Strategy on the Host

Keep the host conda base **minimal** — only tools used for environment management:
```bash
conda install -n base conda-build conda-pack
```

Every project gets a named environment **or** lives in a container. Never `pip install` into the conda base.

### Environment naming convention
```
<project>-<task>-py<version>
# e.g.:
llm-train-py311
vision-infer-py310
scraper-py311
```

---

## VS Code Setup

Install the following extensions (included in your backup):
- **Remote – Containers** (`ms-vscode-remote.remote-containers`) — connect to Docker containers
- **Remote – WSL** (`ms-vscode-remote.remote-wsl`) — connect to WSL2
- **Python** (`ms-python.python`)
- **Pylance** (`ms-python.vscode-pylance`)
- **Jupyter** (`ms-toolsai.jupyter`)
- **GitLens**
- **Docker** (`ms-azuretools.vscode-docker`)

---

## Environment Variable Hygiene

- Keep `PATH` under 1 500 characters
- Never add conda/Python paths to the system PATH; let `conda activate` manage it
- Store secrets in a password manager, not in `%USERPROFILE%\.env`
- Use `.env` files per project (loaded by `python-dotenv` or Docker Compose)

---

## Backup & Recovery Going Forward

Once the new system is live:

1. **Weekly**: run `Backup-System.ps1` to a cloud-synced or external drive.
2. **Per project**: commit `Dockerfile` + `docker-compose.yml` + `conda_env.yml` to the project repo.
3. **Conda envs**: `conda env export > environment.yml` whenever you add a package.
4. **VS Code settings**: sync via Settings Sync (built into VS Code) as a secondary backup.

---

## Quick-start Checklist for the New System

- [ ] Clean install Windows 11
- [ ] Install Windows Updates
- [ ] Run `Setup-NewSystem.ps1 -BundleDir <path>`
- [ ] Verify Docker GPU access: `docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi`
- [ ] Build AI dev container: `cd docker/ai-dev && docker compose up -d`
- [ ] Open VS Code → Dev Containers → Attach to Container
- [ ] Restore conda environments (only non-containerised projects)
- [ ] Configure Windows Terminal profiles
- [ ] Sign in to VS Code Settings Sync
