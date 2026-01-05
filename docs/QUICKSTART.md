# Quick Start - Strix Halo CPU-Only

Fastest path to get llama-swappo-halo running on Strix Halo in CPU-only mode.

## Prerequisites

- k3s installed and running
- kubectl configured
- ~20GB free disk space for models
- Git access to HuggingFace (or use the download script)

## 5-Minute Setup

### Step 1: Clone and Download Models (2 min)

```bash
# Clone the forked repo
git clone https://github.com/SwiggitySwerve/llama-swappo-halo.git
cd llama-swappo-halo

# Download models (interactive selection)
./scripts/download-models.sh --models-dir /var/lib/llama-swappo/models
```

Select:
- `Qwen2.5 Coder 7B Q5` (~5GB, 10 tok/s)
- `DeepSeek Coder V2 Lite Q4` (~9GB, 27 tok/s)

### Step 2: Configure (30 sec)

```bash
# Copy CPU-only config
sudo mkdir -p /etc/llama-swappo
sudo cp config/strix-halo-cpu-only.yaml /etc/llama-swappo/config.yaml

# Verify models directory exists
sudo mkdir -p /var/lib/llama-swappo/models
```

### Step 3: Deploy (1 min)

```bash
# Apply k8s manifests
kubectl apply -f k8s/flux/

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=llama-swappo-halo --timeout=120s
```

### Step 4: Test (30 sec)

```bash
# List models
curl -s http://localhost:8080/v1/models | jq -r '.data[].id'

# Generate code
curl -s http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "deepseek-coder-v2-lite-instruct-q4_k_m", "prompt": "def hello():\n    ", "max_tokens": 20}' \
  | jq -r '.choices[0].text'
```

## Common Issues

### "No space left on device"
```bash
# Check disk space
df -h /var/lib/llama-swappo

# Clean up if needed
sudo rm -rf /var/lib/llama-swappo/models/*
```

### "Port 8080 already in use"
```bash
# Find conflicting deployment
kubectl get deployments --all-namespaces | grep 8080

# Remove old ai-services deployment if exists
kubectl delete deployment -n ai-services llama-swappo
```

### Pod stuck in "Pending"
```bash
# Check events
kubectl describe pod -l app=llama-swappo-halo

# Delete old pod
kubectl delete pod -l app=llama-swappo-halo
```

## Next Steps

- Read [Strix Halo CPU-Only Setup Guide](STRIX_HALLO_CPU_ONLY.md) for detailed documentation
- Configure Flux CD for GitOps: `./scripts/flux-bootstrap.sh`
- Try example scripts in `examples/`

## Performance Tips

1. **Use DeepSeek for speed**: 27 tok/s vs 10 tok/s for Qwen
2. **Reduce context size**: Add `--ctx-size 8192` for faster loading
3. **Monitor resources**: `kubectl top pods -l app=llama-swappo-halo`

## Example Usage

### Python Script

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="dummy"
)

response = client.chat.completions.create(
    model="deepseek-coder-v2-lite-instruct-q4_k_m",
    messages=[{"role": "user", "content": "Write a Python function to parse JSON"}],
    max_tokens=150
)

print(response.choices[0].message.content)
```

### CLI with curl

```bash
# Simple completion
curl http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "prompt": "SELECT * FROM users WHERE ",
    "max_tokens": 50
  }' | jq -r '.choices[0].text'

# Chat completion
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-coder-v2-lite-instruct-q4_k_m",
    "messages": [
      {"role": "user", "content": "Explain what this Rust code does:\n\nfn main() {\n    println!(\"Hello, world!\");\n}"}
    ],
    "max_tokens": 100
  }' | jq -r '.choices[0].message.content'
```
