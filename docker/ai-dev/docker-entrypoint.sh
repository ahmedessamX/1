#!/usr/bin/env bash
# docker-entrypoint.sh — starts JupyterLab inside the ai-dev container
# Override CMD in docker-compose.yml to run a different process.

set -e

# Activate the conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate ai

# Print GPU info on startup
echo "────────────────────────────────────────────"
echo " AI Dev Container"
echo "────────────────────────────────────────────"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null \
    || echo "  [WARN] nvidia-smi not available — GPU passthrough may not be configured"
echo "────────────────────────────────────────────"
python -c "
import torch
print(f'  Python  : {__import__(\"sys\").version.split()[0]}')
print(f'  PyTorch : {torch.__version__}')
print(f'  CUDA    : {torch.version.cuda}')
print(f'  GPU     : {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"NOT AVAILABLE\"}')" 2>/dev/null \
    || echo "  PyTorch not yet installed"
echo "────────────────────────────────────────────"

# Start JupyterLab
exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --notebook-dir=/workspace \
    --ServerApp.token="${JUPYTER_TOKEN:-}" \
    --ServerApp.password="" \
    --ServerApp.allow_root=True
