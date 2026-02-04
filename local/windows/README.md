# Windows Setup

## Prerequisites

- Windows 11 with WSL2
- Docker Desktop
- NVIDIA GPU with drivers (for jade-index)

## Recommended Approach

Use WSL2 for development. See `local/linux/README.md` for WSL2 setup.

## Native Windows (Limited Support)

### 1. Install Scoop

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

### 2. Install tools

```powershell
scoop install nodejs python git gh
```

### 3. Clone projects

```powershell
cd $env:USERPROFILE\projects
git clone https://github.com/jadecli/jade-ecosystem-assist.git
cd jade-ecosystem-assist
git submodule update --init --recursive
```

## WSL2 + Windows Integration

For best experience, run jadecli projects in WSL2 with:
- Docker Desktop (WSL2 backend)
- Ghostty terminal (native Windows or WSL)
- VS Code with Remote WSL extension

See `local/linux/README.md` for the WSL2 setup guide.

## Verification

```powershell
# In PowerShell (native)
wsl jade-start --health

# In WSL2
jade-start --health
```
