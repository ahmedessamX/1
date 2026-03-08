# System Backup & Migration Toolkit

A complete toolkit for **analysing your current Windows system**, **creating a restorable backup bundle**, and **setting up a clean, organised new installation** — with a containerised AI dev environment that eliminates the dependency conflicts common in direct installations.

---

## The Problem This Solves

Running AI/ML workloads directly on Windows leads to:

- Multiple conflicting Python installations and CUDA versions  
- Broken conda environments after system updates  
- A bloated PATH string and hard-to-trace dependency errors  
- No reproducible way to rebuild your environment from scratch  

This toolkit gives you a structured, repeatable path from your messy current setup to a clean, container-based architecture.

---

## Quick Start

### Step 1 — Analyse your current system

```powershell
# Run from PowerShell (no admin required for most sections)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\Analyze-System.ps1
```

Output is written to `%USERPROFILE%\SystemAnalysis\<timestamp>\`. Review the generated files — especially:

| File | What to look for |
|------|-----------------|
| `conflict_analysis.txt` | Warnings about conflicting tools |
| `apps_registry.csv` | All installed apps; identify what you actually use |
| `python_envs.txt` | Conda / pip environments; spot redundant ones |
| `gpu_info.txt` | CUDA versions; multiple installs = conflicts |
| `path_entries.txt` | PATH entries; `Exists = False` means stale entries |

### Step 2 — Create the backup bundle

```powershell
# Backs up packages, conda envs, VS Code, SSH keys, env vars, etc.
.\scripts\Backup-System.ps1 -OutputDir "D:\Backup"

# To also export WSL distributions and Docker images (large):
.\scripts\Backup-System.ps1 -OutputDir "D:\Backup" -ExportWSL -ExportDockerImages
```

> ⚠️ The bundle contains SSH keys and credentials. Store it in an encrypted location.

### Step 3 — Clean install Windows

Do your clean Windows install. Copy the backup bundle to the new machine (USB drive or cloud storage).

### Step 4 — Restore on the new system

```powershell
# Run as Administrator
.\scripts\Setup-NewSystem.ps1 -BundleDir "D:\Backup\2025-05-10_14-30"
```

### Step 5 — Start the AI dev container

```powershell
cd docker/ai-dev
copy .env.example .env   # then edit .env with your API keys
docker compose up -d
```

Open JupyterLab at **http://localhost:8888** and attach VS Code via **Dev Containers: Attach to Running Container**.

---

## Repository Structure

```
├── scripts/
│   ├── Analyze-System.ps1      # Deep system analysis (run before backup)
│   ├── Backup-System.ps1       # Creates the restorable bundle
│   └── Setup-NewSystem.ps1     # Restores from bundle on fresh Windows
│
├── docker/
│   └── ai-dev/
│       ├── Dockerfile           # CUDA 12.4 + PyTorch + HuggingFace
│       ├── docker-compose.yml   # Full dev stack (JupyterLab, TensorBoard, DB)
│       ├── docker-entrypoint.sh # Container startup script
│       ├── requirements.txt     # Python packages (edit as needed)
│       └── .env.example         # Environment variable template
│
├── docs/
│   ├── new-system-architecture.md   # Layer architecture + decisions
│   └── ai-dev-environment.md        # Container usage guide
│
└── config/
    └── winget-baseline.json     # Minimum app list for a fresh install
```

---

## Documentation

- **[New System Architecture](docs/new-system-architecture.md)** — Recommended layer architecture, package manager strategy, Python/conda hygiene, environment variable guidelines.
- **[AI Dev Environment Guide](docs/ai-dev-environment.md)** — How to work with the Docker container: GPU setup, CUDA version matrix, Jupyter, VS Code Dev Containers, troubleshooting.

---

## Key Architectural Decisions

| Decision | Old way | New way |
|----------|---------|---------|
| CUDA | Installed on host (multiple versions) | Lives only inside containers |
| Python | Multiple system installs | Conda base (minimal) + containers |
| AI frameworks | Conda envs on host | Docker containers with GPU passthrough |
| Package manager | Mix of pip, conda, choco, manual | winget (GUI) + Scoop (CLI) + conda (Python only) |
| Secrets | Environment variables / .env files on host | Per-project `.env` loaded by Docker Compose |