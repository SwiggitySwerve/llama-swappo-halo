---
name: llama-model-test
description: Test llama-swappo-halo models for availability, inference quality, and performance. Use when verifying model discovery, testing completions, benchmarking models, or diagnosing model loading issues.
---

# llama-swappo-halo Model Testing

This skill provides comprehensive testing workflows for llama-swappo-halo models, including discovery verification, inference testing, and performance benchmarking.

## When to Use This Skill

Use this skill when the user requests:
- Verifying all 5 models are discovered
- Testing model completions/inference
- Benchmarking model performance
- Comparing different model sizes (3B, 7B, 32B)
- Diagnosing why models aren't loading
- Running the automated test suite

## Available Models

llama-swappo-halo serves 5 CPU-optimized code models:

| Model ID | Name | Size | Context | Use Case |
|----------|------|------|---------|----------|
| `deepseek-coder-v2-lite-instruct-q4_k_m` | DeepSeek-Coder V2 Lite | 2.4B | 16K | Fast, lightweight coding tasks |
| `qwen2.5-coder-3b-instruct-q4_k_m` | Qwen2.5-Coder 3B | 3B | 32K | Quick coding tasks, low memory |
| `qwen2.5-coder-7b-instruct-q5_k_m` | Qwen2.5-Coder 7B | 7B | 32K | Balanced performance/quality (88.4% HumanEval) |
| `gpt-oss-20b-q8_k_xl` | GPT-OSS 20B | 20.9B | 102K | Complex reasoning, long context |
| `qwen2.5-coder-32b-instruct-q5_k_m` | Qwen2.5-Coder 32B | 32B | 32K | Best quality, complex programming (91.6% HumanEval) |

**Note:** All models use CPU-only mode (`HIP_VISIBLE_DEVICES=-1`) due to Strix Halo GPU memory access faults.

## Quick Health Checks

### Verify Service is Running

```bash
# Check health endpoint
curl http://localhost:8080/health

# Expected: HTTP 200 with health status
```

### List All Discovered Models

```bash
# Simple list (should show 5 models)
curl -s http://localhost:8080/v1/models | jq -r '.data[] | .id' | sort

# Detailed model information
curl -s http://localhost:8080/v1/models | jq -r '.data[] | "\(.id) - \(.name) (\(.meta.llamaswap.parameterSize))"' | sort

# Expected output:
# deepseek-coder-v2-lite-instruct-q4_k_m - DeepSeek-Coder V2 Lite Instruct (2.4B)
# gpt-oss-20b-q8_k_xl - GPT-OSS 20B (20.9B)
# qwen2.5-coder-32b-instruct-q5_k_m - Qwen2.5-Coder 32B Instruct (32B)
# qwen2.5-coder-3b-instruct-q4_k_m - Qwen2.5-Coder 3B Instruct (3B)
# qwen2.5-coder-7b-instruct-q5_k_m - Qwen2.5-Coder 7B Instruct (7B)
```

### Quick Inference Test

```bash
# Test a simple completion with the 7B model
curl -s http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "messages": [{"role": "user", "content": "Write a Python hello world"}],
    "max_tokens": 100
  }' | jq -r '.choices[0].message.content'
```

## Automated Test Suite

The project includes a comprehensive Python test suite.

### Run Full Test Suite

```bash
# Test all 5 models with various prompts
cd /home/swiggity/Projects/llama-swappo-halo
python examples/test_models.py

# Expected output:
# Testing model: deepseek-coder-v2-lite-instruct-q4_k_m
# ✓ Simple completion test passed
# ✓ Code generation test passed
#
# Testing model: qwen2.5-coder-7b-instruct-q5_k_m
# ... (repeats for all 5 models)
```

### Quick One-Liner Tests

```bash
# Test all models with quick prompts
./examples/quick_tests.sh all

# Test specific model
./examples/quick_tests.sh qwen2.5-coder-7b-instruct-q5_k_m

# Test code generation across all models
./examples/quick_tests.sh code
```

## Interactive Testing

### Interactive Chat Session

```bash
# Launch interactive CLI chat
python examples/interactive_chat.py

# You'll be prompted to select a model, then can chat interactively
# Type 'quit' or 'exit' to end session
```

### Manual cURL Testing

Test individual models with custom prompts:

```bash
# Basic completion
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-32b-instruct-q5_k_m",
    "messages": [
      {"role": "system", "content": "You are a helpful coding assistant."},
      {"role": "user", "content": "Explain how Python list comprehensions work"}
    ],
    "max_tokens": 500,
    "temperature": 0.7
  }' | jq .

# Streaming response
curl -N http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "messages": [{"role": "user", "content": "Write a Fibonacci function"}],
    "max_tokens": 200,
    "stream": true
  }'
```

## Performance Benchmarking

### Measure Inference Speed

```bash
# Time a completion
time curl -s http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "messages": [{"role": "user", "content": "Write a sorting algorithm"}],
    "max_tokens": 500
  }' > /dev/null

# Compare different model sizes
for model in \
  "qwen2.5-coder-3b-instruct-q4_k_m" \
  "qwen2.5-coder-7b-instruct-q5_k_m" \
  "qwen2.5-coder-32b-instruct-q5_k_m"; do
  echo "Testing $model..."
  time curl -s http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$model\",
      \"messages\": [{\"role\": \"user\", \"content\": \"Write hello world\"}],
      \"max_tokens\": 50
    }" > /dev/null
done
```

### Monitor Resource Usage

```bash
# Check CPU/memory usage during inference
kubectl top pod -l app=llama-swappo-halo

# Watch resource usage in real-time
watch kubectl top pod -l app=llama-swappo-halo
```

## Troubleshooting Model Issues

### Models Not Discovered (Fewer than 5)

```bash
# 1. Check how many models are available
curl -s http://localhost:8080/v1/models | jq '.data | length'

# 2. If fewer than 5, check ConfigMap
kubectl get configmap llama-swappo-halo-config -o yaml | grep -A 10 "models:"

# 3. Verify model files exist on host
ls -lh /var/lib/llama-swappo/models/*/

# 4. Restart deployment to reload config
kubectl delete pod -l app=llama-swappo-halo

# 5. Verify all 5 models after restart
curl -s http://localhost:8080/v1/models | jq -r '.data[] | .id' | sort
```

### Model Returns Errors During Inference

```bash
# Check pod logs for errors
kubectl logs -f deployment/llama-swappo-halo | grep -i error

# Verify model file exists and is readable
kubectl exec deployment/llama-swappo-halo -- ls -lh /models/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/

# Check model path in config matches actual file location
kubectl exec deployment/llama-swappo-halo -- cat /app/config.yaml | grep -A 5 "qwen2.5-coder-7b"
```

### Slow Inference / Performance Issues

**All models use CPU-only mode** due to Strix Halo GPU issues.

```bash
# 1. Verify CPU-only mode is enabled
kubectl exec deployment/llama-swappo-halo -- cat /app/config.yaml | grep -A 2 "HIP_VISIBLE_DEVICES"

# Expected:
# env:
#   - "HIP_VISIBLE_DEVICES=-1"  # Hide GPU from ROCm

# 2. Check thread count in macros
kubectl exec deployment/llama-swappo-halo -- cat /app/config.yaml | grep -A 3 "macros:"

# 3. Use smaller models for faster inference:
# - 3B model: Fastest (qwen2.5-coder-3b-instruct-q4_k_m)
# - 7B model: Balanced (qwen2.5-coder-7b-instruct-q5_k_m)
# - 32B model: Slowest but best quality (qwen2.5-coder-32b-instruct-q5_k_m)
```

## Model Comparison Testing

Test the same prompt across all models to compare:

```bash
#!/bin/bash
# Save as test_all_models.sh

PROMPT="Write a Python function to calculate factorial"

for model in \
  "deepseek-coder-v2-lite-instruct-q4_k_m" \
  "qwen2.5-coder-3b-instruct-q4_k_m" \
  "qwen2.5-coder-7b-instruct-q5_k_m" \
  "gpt-oss-20b-q8_k_xl" \
  "qwen2.5-coder-32b-instruct-q5_k_m"; do

  echo "========================================="
  echo "Model: $model"
  echo "========================================="

  curl -s http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$model\",
      \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
      \"max_tokens\": 300
    }" | jq -r '.choices[0].message.content'

  echo ""
  echo ""
done
```

## API Compatibility Testing

llama-swappo provides an Ollama-compatible API:

```bash
# Test /v1/models endpoint (OpenAI format)
curl http://localhost:8080/v1/models | jq .

# Test /api/tags endpoint (Ollama format)
curl http://localhost:8080/api/tags | jq .

# Test /v1/chat/completions (OpenAI format)
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "messages": [{"role": "user", "content": "Hello"}]
  }' | jq .

# Test streaming
curl -N http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-7b-instruct-q5_k_m",
    "messages": [{"role": "user", "content": "Count to 10"}],
    "stream": true
  }'
```

## Expected Test Results

After a successful deployment, you should see:

1. **5 models discovered** via `/v1/models`
2. **All models respond** to completion requests
3. **No errors** in pod logs
4. **CPU-only mode enabled** (HIP_VISIBLE_DEVICES=-1)
5. **Reasonable inference speed** (varies by model size)

## Model Selection Guidelines

**For quick tasks (< 5 seconds):**
- Use 3B model: `qwen2.5-coder-3b-instruct-q4_k_m`
- Use 2.4B model: `deepseek-coder-v2-lite-instruct-q4_k_m`

**For balanced quality/speed:**
- Use 7B model: `qwen2.5-coder-7b-instruct-q5_k_m` (88.4% HumanEval)

**For complex tasks requiring best quality:**
- Use 32B model: `qwen2.5-coder-32b-instruct-q5_k_m` (91.6% HumanEval)
- Use 20B model: `gpt-oss-20b-q8_k_xl` (long 102K context)

**For long context tasks (> 16K tokens):**
- Avoid DeepSeek-Coder V2 Lite (16K limit)
- Use Qwen models or GPT-OSS (32K-102K context)
