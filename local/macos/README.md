# macOS Setup

## Prerequisites

- macOS 13+ (Ventura or later)
- Homebrew
- Docker Desktop

## Quick Setup

```bash
# From jade-ecosystem-assist
./local/macos/setup.sh
```

## Manual Steps

### 1. Install Homebrew (if not present)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install mise (version manager)

```bash
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

### 3. Install tools via mise

```bash
mise use -g node@22
mise use -g python@3.12
mise use -g uv@latest
```

### 4. Clone dotfiles

```bash
brew install chezmoi age
chezmoi init https://github.com/jadecli/dotfiles.git
chezmoi apply
```

### 5. Start infrastructure

```bash
cd ~/projects/jadecli-infra
docker compose up -d
```

## Notes

- GPU acceleration uses MPS (Metal Performance Shaders) on Apple Silicon
- Adjust PYTORCH_DEVICE=mps in jade-index config for M-series Macs

## Verification

```bash
jade-start --health
```
