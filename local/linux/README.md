# Linux Setup (WSL2/Ubuntu)

## Prerequisites

- WSL2 with Ubuntu 24.04+
- NVIDIA GPU with CUDA drivers (for jade-index)
- Docker Desktop with WSL2 backend

## Quick Setup

```bash
# From jade-ecosystem-assist
./local/linux/setup.sh
```

## Manual Steps

### 1. Install mise (version manager)

```bash
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
```

### 2. Install tools via mise

```bash
mise use -g node@22
mise use -g python@3.12
mise use -g uv@latest
```

### 3. Clone dotfiles

```bash
chezmoi init https://github.com/jadecli/dotfiles.git
chezmoi apply
```

### 4. Start infrastructure

```bash
cd ~/projects/jadecli-infra
docker compose up -d
```

### 5. GPU Setup (for jade-index)

```bash
# Install NVIDIA container toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

## Verification

```bash
jade-start --health
```
