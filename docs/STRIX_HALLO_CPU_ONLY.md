# Strix Halo CPU-Only Setup Guide

This guide covers running llama-swappo-halo on AMD Strix Halo (gfx1151) in CPU-only mode.

## Overview

**Why CPU-only?**
The llama.cpp binary included in this container has GPU support compiled in for gfx1151, but may encounter memory access faults when trying to use the integrated GPU. The workaround is to force CPU-only mode using the `HIP_VISIBLE_DEVICES=-1` environment variable.

**Performance:**
- Qwen2.5-Coder-7B Q5_K_M: ~10 tokens/second
- DeepSeek-Coder-V2-Lite Q4_K_M: ~27 tokens/second
- Models run slower than GPU but are fully functional

## Models Configured

### Qwen2.5-Coder-7B (Q5_K_M)
- **Size**: 5.07GB
- **HumanEval**: 88.4%
- **Context**: 32K tokens
- **Use Case**: General code generation, larger projects

### DeepSeek-Coder-V2-Lite (Q4_K_M)
- **Size**: 9.65GB
- **HumanEval**: 89%
- **Context**: 16K tokens
- **Use Case**: Fast code generation, smaller projects

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/SwiggitySwerve/llama-swappo-halo.git
cd llama-swappo-halo
```

### 2. Download Models

Use the provided script to download models:

```bash
# List available models
./scripts/download-models.sh --list

# Download models interactively
./scripts/download-models.sh --models-dir /var/lib/llama-swappo/models

# Or manually download:
mkdir -p /var/lib/llama-swappo/models/{Qwen/Qwen2.5-Coder-7B-Instruct-GGUF,bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF}

# Qwen2.5-Coder-7B
wget -P /var/lib/llama-swappo/models/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF \
  https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q5_k_m.gguf

# DeepSeek-Coder-V2-Lite
wget -P /var/lib/llama-swappo/models/bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF \
  https://huggingface.co/bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF/resolve/main/DeepSeek-Coder-V2-Lite-Instruct-Q4_K_M.gguf
```

### 3. Configure Models

Copy the CPU-only configuration:

```bash
sudo mkdir -p /etc/llama-swappo
sudo cp config/strix-halo-cpu-only.yaml /etc/llama-swappo/config.yaml
```

**Important Configuration Details:**
- `--n-gpu-layers 0`: Disable GPU offloading
- `HIP_VISIBLE_DEVICES=-1`: Hide GPU from llama.cpp to prevent memory access faults

### 4. Deploy to k3s

```bash
kubectl apply -f k8s/flux/
```

Or use the provided helper script:

```bash
./scripts/k8s-deploy.sh
```

### 5. Verify Deployment

```bash
# Check pod status
kubectl get pods -l app=llama-swappo-halo

# Check logs
kubectl logs -l app=llama-swappo-halo --tail=20

# List available models
curl -s http://localhost:8080/v1/models | jq .
```

## Configuration File

The CPU-only configuration at `/etc/llama-swappo/config.yaml` includes:

```yaml
models:
  "qwen2.5-coder-7b-instruct-q5_k_m":
    cmd: |
      ${llama}
      -m /models/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/qwen2.5-coder-7b-instruct-q5_k_m.gguf
      --ctx-size 32768
      --n-gpu-layers 0
    name: "Qwen2.5-Coder 7B Instruct"
    env:
      - "HIP_VISIBLE_DEVICES=-1"  # Critical: Hide GPU to prevent crashes
    metadata:
      architecture: "qwen2.5"
      contextLength: 32768
      parameterSize: "7B"
      quantizationLevel: "Q5_K_M"

  "deepseek-coder-v2-lite-instruct-q4_k_m":
    cmd: |
      ${llama}
      -m /models/bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF/DeepSeek-Coder-V2-Lite-Instruct-Q4_K_M.gguf
      --ctx-size 16384
      --n-gpu-layers 0
    name: "DeepSeek-Coder V2 Lite Instruct"
    env:
      - "HIP_VISIBLE_DEVICES=-1"  # Critical: Hide GPU to prevent crashes
    metadata:
      architecture: "deepseek-coder"
      contextLength: 16384
      parameterSize: "2.4B"
      quantizationLevel: "Q4_K_M"

groups:
  main:
    swap: true
    exclusive: true
    members:
      - "qwen2.5-coder-7b-instruct-q5_k_m"
      - "deepseek-coder-v2-lite-instruct-q4_k_m"
```

## API Usage

The service provides an Ollama-compatible API on port 8080.

### List Models

```bash
curl http://localhost:8080/v1/models | jq .
```

### Generate Code (Completions API)

```bash
curl http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "prompt": "def fibonacci(n):\n    ",
    "max_tokens": 100
  }' | jq -r '.choices[0].text'
```

### Generate Code (Chat Completions API)

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
    "messages": [
      {"role": "user", "content": "Write a Python function to calculate factorial"}
    ],
    "max_tokens": 200
  }' | jq -r '.choices[0].message.content'
```

### Using with OpenAI Python Client

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="dummy"  # Not used but required by client
)

response = client.chat.completions.create(
    model="qwen2.5-coder-7b-instruct-q5_k_m",
    messages=[
        {"role": "user", "content": "Write a Go function to reverse a string"}
    ],
    max_tokens=200
)

print(response.choices[0].message.content)
```

## Troubleshooting

### Models crash with "Memory access fault by GPU node-1"

**Problem**: llama.cpp detects the GPU and attempts to use it, causing crashes.

**Solution**: Ensure `HIP_VISIBLE_DEVICES=-1` is set in the model's `env` section:
```yaml
env:
  - "HIP_VISIBLE_DEVICES=-1"
```

### Models don't appear in `/v1/models`

**Problem**: Model paths are incorrect or models aren't downloaded.

**Solution**:
```bash
# Verify model files exist
ls -la /var/lib/llama-swappo/models/

# Check pod logs for errors
kubectl logs -l app=llama-swappo-halo

# Verify config is mounted
kubectl exec -it <pod-name> -- cat /app/config.yaml
```

### Deployment stuck in "Pending" state

**Problem**: Port 8080 already in use.

**Solution**:
```bash
# Find and remove conflicting deployments
kubectl get deployments --all-namespaces
kubectl delete deployment <conflicting-deployment>

# Or find process using port 8080
sudo lsof -i :8080
```

### Slow performance

**Problem**: CPU-only mode is slower than GPU.

**Solutions**:
1. Use the smaller/faster DeepSeek model for quick tasks
2. Increase CPU resources in deployment.yaml if needed:
   ```yaml
   resources:
     requests:
       cpu: "4"  # Increase from default
     limits:
       cpu: "16"
   ```
3. Reduce context size if not needed: `--ctx-size 8192`

## Performance Tuning

### Context Size

Adjust `--ctx-size` based on your needs:
- `8192` (8K): Quick tasks, less memory
- `16384` (16K): Medium tasks (default for DeepSeek)
- `32768` (32K): Large projects (default for Qwen)

### Batch Size

Adjust in the llama macro:
```yaml
macros:
  "llama": >
    /usr/local/bin/llama-server
    --port ${PORT}
    --host 0.0.0.0
    --n-gpu-layers 0
    --batch-size 256  # Reduce from 512 for lower latency
    --ubatch-size 256
    --threads 8       # Match your CPU cores
```

### Thread Count

Set `--threads` to match your CPU cores for best performance:
```bash
# Check available cores
nproc

# Update config with thread count
--threads $(nproc)
```

## Reference

- [llama-swappo Documentation](https://github.com/Mootikins/llama-swappo)
- [Qwen2.5-Coder Paper](https://arxiv.org/abs/2409.12186)
- [DeepSeek-Coder V2 Paper](https://github.com/deepseek-ai/DeepSeek-Coder-V2)
- [Ollama API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)

## Hardware

- **CPU**: AMD Strix Halo APU
- **iGPU**: Radeon 8060S (gfx1151) - Disabled for this setup
- **RAM**: Recommended 32GB+ for 7B models
