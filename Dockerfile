FROM nvcr.io/nvidia/cuda:13.0.1-devel-ubuntu24.04

ARG DEBIAN_FRONTEND=noninteractive

# 1. Install system packages + Python 3.10 from deadsnakes
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl wget build-essential software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3.10-venv python3.10-distutils python3.10-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Create venv and upgrade pip/setuptools/wheel inside it
RUN python3.10 -m venv /opt/py310 \
    && /opt/py310/bin/python -m pip install --upgrade pip setuptools wheel

# 3. Use venv (/opt/py310) by default
ENV PATH="/opt/py310/bin:${PATH}"

# 4. Clone repo
RUN git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1 /workspace/Hunyuan3D-2.1
WORKDIR /workspace/Hunyuan3D-2.1

# 5. Install Python dependencies (PyTorch CUDA 12.4 build first, then project requirements)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

RUN pip install -r requirements.txt

# 6. Build and install hy3dpaint custom rasterizer and compile differentiable renderer
RUN bash -lc "cd hy3dpaint/custom_rasterizer && pip install -e ." \
    && bash -lc "cd hy3dpaint/DifferentiableRenderer && bash compile_mesh_painter.sh"

# 7. Download ESRGAN weights
RUN mkdir -p hy3dpaint/ckpt \
    && wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -P hy3dpaint/ckpt

# 5. Test docker works and nvidia hardware and python is ready
CMD bash -lc "nvidia-smi && python --version && echo 'Container ready' && bash"

LABEL authors="dr-vij"