# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**llama-swappo-halo** is a container image for running llama-swappo (an LLM proxy with Ollama-compatible API) on AMD Strix Halo hardware (gfx1151) with ROCm acceleration. This is a fork that adds CPU-only mode support for Strix Halo due to GPU memory access faults with the integrated GPU.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    llama-swappo-halo                    │
│  ┌───────────────────────────────────────────────────┐  │
│  │  llama-swap (Go proxy)                            │  │
│  │  - Ollama API translation                         │  │
│  │  - Model management & swapping                    │  │
│  │  - Port 8080                                      │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│                          ▼                               │
│  ┌───────────────────────────────────────────────────┐  │
│  │  llama-server (llama.cpp)                         │  │
│  │  - GGUF model loading                             │  │
│  │  - Dynamic port assignment                        │  │
│  │  - CPU-only or GPU (ROCm)                         │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    k3s Cluster                          │
│  - Flux CD for GitOps automation                        │
│  - hostNetwork: true for LAN access                    │
│  - Models stored on host at /var/lib/llama-swappo/models│
└─────────────────────────────────────────────────────────┘
```

### Key Components

- **llama-swap**: Go binary that provides Ollama-compatible API, manages model swapping, handles health checks
- **llama-server**: Pre-built from kyuz0/amd-strix-halo-toolboxes, loads GGUF models
- **config.yaml**: Defines model groups, macros (command templates), and individual model configurations
- **Flux CD**: GitOps automation that syncs manifests from `k8s/flux/` to cluster

## Common Development Commands

### Building the Container

```bash
# Standard build (LLM proxy only)
./build.sh

# With Whisper STT support (requires local build, ~5GB toolchain)
./build.sh --whisper

# Push to GitHub Container Registry
./build.sh --ghcr
```

### Kubernetes Operations

```bash
# Deploy to cluster
kubectl apply -f k8s/flux/

# Restart deployment (e.g., after config change)
kubectl rollout restart deployment/llama-swappo-halo

# View logs
./scripts/k8s-logs.sh

# Check pod status
kubectl get pods -l app=llama-swappo-halo

# Access shell in running pod
kubectl exec -it deployment/llama-swappo-halo -- sh
```

### Flux CD GitOps

```bash
# Check sync status
flux get kustomizations
flux get sources git
flux get sources image

# Force immediate sync
flux reconcile kustomization flux-system --with-source

# View all Flux resources
./scripts/flux-status.sh

# View Flux logs
./scripts/k8s-logs.sh --flux
```

### Model Management

```bash
# List available models
./scripts/download-models.sh --list

# Download models interactively
./scripts/download-models.sh --models-dir /var/lib/llama-swappo/models

# Update config after downloading models
sudo cp config/strix-halo-cpu-only.yaml /etc/llama-swappo/config.yaml
# Edit the file to uncomment model entries
kubectl rollout restart deployment/llama-swappo-halo
```

### Testing

```bash
# Quick health check
curl http://localhost:8080/health

# List available models
curl http://localhost:8080/v1/models | jq .

# Run automated test suite
python examples/test_models.py

# Run quick one-liner tests
./examples/quick_tests.sh all

# Interactive chat CLI
python examples/interactive_chat.py
```

## Configuration Architecture

### config.yaml Structure

1. **General settings**: Health check timeout, TTL for model caching, logging
2. **groups**: Define model groups with swapping behavior
   - `swap: true` - Only one model from this group loaded at a time
   - `exclusive: true` - Cannot run alongside other groups
3. **macros**: Command templates reused across models (llama, llama-embed, whisper)
4. **models**: Individual model configurations that reference macros
5. **hooks**: Startup behavior (preloading models)

### Model Configuration Pattern

```yaml
models:
  "model-id":
    cmd: |
      ${macro-name}
      -m /models/path/to/model.gguf
      --ctx-size 32768
      --n-gpu-layers 0  # 0 for CPU-only, -1 for all GPU layers
    name: "Display Name"
    description: "Human-readable description"
    env:
      - "HIP_VISIBLE_DEVICES=-1"  # Hide GPU (CPU-only mode)
    metadata:
      architecture: "qwen2.5"
      contextLength: 32768
      capabilities: [completion, tools]
      family: "qwen"
```

### CPU-Only Mode (Strix Halo Workaround)

**Problem**: llama.cpp detects gfx1151 GPU but crashes with memory access faults

**Solution**: Set `HIP_VISIBLE_DEVICES=-1` to hide GPU from llama.cpp, then use `--n-gpu-layers 0`

```yaml
env:
  - "HIP_VISIBLE_DEVICES=-1"
cmd: |
  ${llama}
  --n-gpu-layers 0  # Force CPU-only
```

## Deployment Configuration

### Kubernetes Deployment

- **Namespace**: `default`
- **Replicas**: 1
- **Network**: `hostNetwork: true` (pod uses host network for LAN access)
- **Storage**:
  - Models: `/var/lib/llama-swappo/models` (hostPath)
  - Config: `/etc/llama-swappo/config.yaml` (hostPath)
  - GPU devices: `/dev/dri`, `/dev/kfd` (hostPath, privileged mode)

### Service Exposure

The service uses `hostNetwork: true` for direct LAN access:
- Service accessible on host's network interfaces
- Default port: `8080`
- No ClusterIP needed for internal cluster access

**Note**: Traefik and cert-manager are NOT used in this cluster. Use an external reverse proxy for SSL/termination.

### Config Change Workflow

1. Edit `/etc/llama-swappo/config.yaml` on host
2. Restart deployment: `kubectl rollout restart deployment/llama-swappo-halo`
3. llama-swap picks up new config on next request
4. Models are swapped in/out dynamically based on group configuration

## Important File Locations

- **Config**: `/etc/llama-swappo/config.yaml` (mounted into pod at `/app/config.yaml`)
- **Models**: `/var/lib/llama-swappo/models/` (mounted into pod at `/models/`)
- **Manifests**: `k8s/flux/` (managed by Flux CD)
- **Example configs**: `config/strix-halo-cpu-only.yaml` (recommended for Strix Halo)

## Troubleshooting

### Common Issues

**Models not loading**: Check logs, verify model paths in config.yaml match actual file locations

**GPU crashes**: Use CPU-only mode (`HIP_VISIBLE_DEVICES=-1`, `--n-gpu-layers 0`)

**Flux not syncing**: Check `flux get kustomizations`, force reconcile with `flux reconcile kustomization flux-system --with-source`

**Service not accessible**: Verify `hostNetwork: true` in deployment, check host firewall

### Log Viewing

```bash
# Application logs
kubectl logs -f deployment/llama-swappo-halo

# Flux logs
./scripts/k8s-logs.sh --flux

# All logs (app + Flux)
./scripts/k8s-logs.sh
```

### Health Checks

```bash
# Service health
curl http://localhost:8080/health

# Model availability
curl http://localhost:8080/v1/models | jq .

# Flux status
flux check
```

## Fork-Specific Changes

This fork by SwiggitySwerve adds:

1. **CPU-only mode** for Strix Halo (GPU workaround)
2. **Pre-configured models**: Qwen2.5-Coder-7B, DeepSeek-Coder-V2-Lite
3. **Documentation**: QUICKSTART.md, STRIX_HALLO_CPU_ONLY.md, API_USAGE_GUIDE.md
4. **Testing suite**: test_models.py, interactive_chat.py, quick_tests.sh
5. **Helper scripts**: download-models.sh with curated model list

**Do not push CPU-only changes to upstream** - they are specific to Strix Halo GPU issues.

## Related Repositories

- **llama-swappo**: https://github.com/Mootikins/llama-swappo (proxy application)
- **amd-strix-halo-toolboxes**: https://github.com/kyuz0/amd-strix-halo-toolboxes (base image with llama.cpp)
- **llama.cpp**: https://github.com/ggerganov/llama.cpp (GGUF model runtime)
