# AI Dev Container — Dockerfile
#
# Base: NVIDIA CUDA 12.4 + cuDNN 9 on Ubuntu 22.04
# Change the FROM line to switch CUDA versions (see docs/ai-dev-environment.md).
#
# Build:  docker compose up -d
# Shell:  docker exec -it ai-dev bash

ARG CUDA_VERSION=12.4.1
ARG CUDNN_VERSION=9
ARG UBUNTU_VERSION=22.04

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-devel-ubuntu${UBUNTU_VERSION}

# ── Labels ──────────────────────────────────────────────────────────────────
LABEL maintainer="you@example.com"
LABEL description="AI / ML development environment with CUDA, PyTorch, HuggingFace"

# ── System packages ──────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Python build deps
    python3.11 python3.11-dev python3.11-venv python3-pip \
    # Utilities
    git curl wget vim nano tmux htop \
    # Compression
    zip unzip tar \
    # Networking / debug
    iputils-ping net-tools \
    # OpenCV / image processing deps
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev \
    # Audio processing deps
    libsndfile1 ffmpeg \
    # Build tools
    build-essential cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Python 3.11 as default ───────────────────────────────────────────────────
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
 && python -m pip install --upgrade "pip==24.2" "setuptools==70.3.0" "wheel==0.44.0"

# ── Conda (Miniconda) ────────────────────────────────────────────────────────
ENV CONDA_DIR=/opt/conda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
 && bash /tmp/miniconda.sh -b -p ${CONDA_DIR} \
 && rm /tmp/miniconda.sh \
 && ${CONDA_DIR}/bin/conda clean -tipsy

ENV PATH="${CONDA_DIR}/bin:${PATH}"
RUN conda init bash && conda config --set auto_activate_base false

# ── Create project conda environment ────────────────────────────────────────
# Copies requirements.txt if it exists; otherwise creates a minimal env.
COPY requirements.txt /tmp/requirements.txt

RUN conda create -n ai python=3.11 -y \
 && conda run -n ai pip install --upgrade pip \
 && conda run -n ai pip install -r /tmp/requirements.txt

# Make the 'ai' env the default for all bash sessions
RUN echo "conda activate ai" >> ~/.bashrc

# ── HuggingFace cache directory ───────────────────────────────────────────────
ENV HF_HOME=/workspace/.cache/huggingface
RUN mkdir -p ${HF_HOME}

# ── Working directory ─────────────────────────────────────────────────────────
WORKDIR /workspace

# ── JupyterLab configuration ──────────────────────────────────────────────────
RUN conda run -n ai jupyter lab --generate-config
RUN conda run -n ai jupyter lab --ServerApp.token='' --ServerApp.password='' \
    --ServerApp.open_browser=False 2>/dev/null || true

# ── Expose ports ──────────────────────────────────────────────────────────────
# JupyterLab
EXPOSE 8888
# TensorBoard
EXPOSE 6006
# General-purpose (FastAPI, Gradio, Streamlit, etc.)
EXPOSE 7860
EXPOSE 8000

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

CMD ["/usr/local/bin/docker-entrypoint.sh"]
