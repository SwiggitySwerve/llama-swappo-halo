# llama-swappo-halo

[![Build & Push Container](https://github.com/Mootikins/llama-swappo-halo/actions/workflows/build.yml/badge.svg)](https://github.com/Mootikins/llama-swappo-halo/actions/workflows/build.yml)

Container image for running [llama-swappo](https://github.com/Mootikins/llama-swappo) (LLM proxy with Ollama API) on AMD Strix Halo (gfx1151) with ROCm.

Based on [kyuz0/amd-strix-halo-toolboxes](https://github.com/kyuz0/amd-strix-halo-toolboxes) which provides llama.cpp pre-built for gfx1151.

## Features

- llama-swappo proxy with Ollama API translation
- llama.cpp with ROCm/HIP acceleration for gfx1151
- Optional: whisper.cpp for speech-to-text
- CPU-only mode support for Strix Halo (with workaround for GPU memory issues)

## Build

```bash
# LLM proxy only (default)
./build.sh

# With Whisper STT support
./build.sh --whisper
```

## Quick Start

### Strix Halo CPU-Only Mode (Recommended)

The llama.cpp binary in this container has GPU support for gfx1151, but may encounter memory access faults when using the integrated GPU. The recommended setup is CPU-only mode:

**5-Minute Setup:**
```bash
# 1. Clone and download models
git clone https://github.com/SwiggitySwerve/llama-swappo-halo.git
cd llama-swappo-halo
./scripts/download-models.sh --models-dir /var/lib/llama-swappo/models

# 2. Configure
sudo mkdir -p /etc/llama-swappo
sudo cp config/strix-halo-cpu-only.yaml /etc/llama-swappo/config.yaml

# 3. Deploy
kubectl apply -f k8s/flux/

# 4. Test
curl -s http://localhost:8080/v1/models | jq .
```

**Documentation:**
- [Quick Start Guide](docs/QUICKSTART.md) - Fastest path to running
- [Strix Halo CPU-Only Setup](docs/STRIX_HALLO_CPU_ONLY.md) - Comprehensive guide with troubleshooting

**Configured Models:**
- Qwen2.5-Coder-7B Q5_K_M (5GB, 88.4% HumanEval) - ~10 tok/s
- DeepSeek-Coder-V2-Lite Q4_K_M (9GB, 89% HumanEval) - ~27 tok/s

### Docker/Podman (GPU Mode)

For testing with GPU acceleration:

```bash
# Pull from ghcr.io
docker pull ghcr.io/mootikins/llama-swappo-halo:latest

# Run (docker/podman/nerdctl)
docker run --rm -it \
  --device /dev/dri --device /dev/kfd \
  -v /path/to/models:/models:ro \
  -v /path/to/config.yaml:/app/config.yaml:ro \
  -p 8080:8080 \
  ghcr.io/mootikins/llama-swappo-halo:latest \
  -config /app/config.yaml
```

## GitOps Deployment with Flux CD

This repository includes Flux CD GitOps automation for easy deployment to k3s.

### Initial Setup

Install Flux CLI and bootstrap:
```bash
# Install Flux CLI
curl -sL https://fluxcd.io/install.sh | sudo bash

# Bootstrap Flux on k3s
flux bootstrap github \
  --owner=mootikins \
  --repository=llama-swappo-halo \
  --branch=main \
  --path=./k8s/flux \
  --personal \
  --interval=1m
```

### Flux GitOps Workflow

With Flux installed, deployments are automated:

1. **Make changes** to manifests in `k8s/flux/`
2. **Commit and push** to GitHub
3. **Flux automatically applies** changes to the cluster

No manual `kubectl apply` needed!

### Helper Scripts

- `./scripts/flux-sync.sh` - Force immediate sync and show status
- `./scripts/flux-status.sh` - Display all Flux resources and status
- `./scripts/k8s-logs.sh` - Enhanced log viewing for app and Flux

### Common Operations

```bash
# Check sync status
flux get kustomizations

# Force immediate sync
flux reconcile kustomization flux-system --with-source

# View Flux resources
flux get sources git
flux get sources image

# Rollback (via Git)
git revert HEAD
git push  # Flux will auto-apply the revert
```

### Image Automation

Flux can automatically update deployments when new container images are pushed to ghcr.io. This is configured in `k8s/flux/image-*.yaml`.

### Troubleshooting

```bash
# Check Flux controller status
kubectl get pods -n flux-system

# View Flux logs
./scripts/k8s-logs.sh --flux

# Check for errors
kubectl get events -n flux-system --field-selector type=Warning

# Verify prerequisites
flux check --pre
```

For more details, see [k8s/README.md](k8s/README.md).

## Configuration

See [llama-swappo documentation](https://github.com/Mootikins/llama-swappo) for config.yaml format.

## Whisper STT

The whisper-enabled image must be built locally (ROCm toolchain ~5GB exceeds CI runner limits):

```bash
./build.sh --whisper
```

When built with `--whisper`, the image includes:

- `/app/whisper-server` - HTTP server for transcription
- `/app/whisper-cli` - CLI tool for transcription
- `ffmpeg` for audio processing

To use whisper alongside llama-swappo, configure llama-swappo to spawn whisper-server as needed, or run them as separate processes.

## Requirements

- AMD Strix Halo APU (gfx1151) or compatible
- ROCm drivers installed on host
- Access to `/dev/dri` and `/dev/kfd`

## License

MIT
