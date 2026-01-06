#!/bin/bash
# Helper script to download LLM models from HuggingFace
#
# Usage:
#   ./scripts/download-models.sh --models-dir /var/lib/llama-swappo/models
#   ./scripts/download-models.sh --list

set -e

MODELS_DIR="${MODELS_DIR:-/var/lib/llama-swappo/models}"
LIST_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --models-dir)
      MODELS_DIR="$2"
      shift 2
      ;;
    --list)
      LIST_ONLY=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --models-dir DIR    Directory to store models (default: /var/lib/llama-swappo/models)"
      echo "  --list              List available models without downloading"
      echo "  -h, --help          Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Model definitions: NAME|HUGGINGFACE_REPO|FILE_PATTERN|OUTPUT_SUBDIR
MODELS=(
  "Nomic Embed v1.5 Q8|nomic-ai/nomic-embed-text-v1.5-GGUF|*Q8_0.gguf|nomic-ai/nomic-embed-text-v1.5-GGUF"
  "Qwen2.5 Coder 3B Q4|Qwen/Qwen2.5-Coder-3B-Instruct-GGUF|*q4_k_m.gguf|Qwen/Qwen2.5-Coder-3B-Instruct-GGUF"
  "Qwen2.5 Coder 7B Q5|Qwen/Qwen2.5-Coder-7B-Instruct-GGUF|*Q5_K_M.gguf|Qwen/Qwen2.5-Coder-7B-Instruct-GGUF"
  "Qwen2.5 Coder 32B Q5|Qwen/Qwen2.5-Coder-32B-Instruct-GGUF|*Q5_K_M.gguf|Qwen/Qwen2.5-Coder-32B-Instruct-GGUF"
  "DeepSeek Coder V2 Lite Q4|bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF|*Q4_K_M.gguf|bartowski/DeepSeek-Coder-V2-Lite-Instruct-GGUF"
  "Llama 3.2 3B Q8|lmstudio-community/Meta-Llama-3.2-3B-Instruct-GGUF|*Q8_0.gguf|Meta-Llama-3.2-3B-Instruct-GGUF"
  "Phi-3 Mini Q4|microsoft/Phi-3-mini-4k-instruct-gguf|*q4_k_m.gguf|microsoft/Phi-3-mini-4k-instruct-gguf"
  "GPT-OSS 20B Q8|unsloth/gpt-oss-20b-GGUF|*Q8_K_XL.gguf|unsloth/gpt-oss-20b-GGUF"
)

# Available Whisper models
WHISPER_MODELS=(
  "Whisper Tiny|ggerganov/whisper.cpp|ggml-tiny.bin|whisper"
  "Whisper Base|ggerganov/whisper.cpp|ggml-base.bin|whisper"
  "Whisper Small|ggerganov/whisper.cpp|ggml-small.bin|whisper"
  "Whisper Medium|ggerganov/whisper.cpp|ggml-medium.bin|whisper"
  "Whisper Large v3 Turbo|ggerganov/whisper.cpp|ggml-large-v3-turbo.bin|whisper"
)

list_models() {
  echo "=== Available LLM Models ==="
  echo ""
  for model in "${MODELS[@]}"; do
    IFS='|' read -r name repo file subdir <<< "$model"
    echo "  • $name"
    echo "    Repo: $repo"
    echo "    File: $file"
    echo ""
  done

  echo "=== Available Whisper Models (requires Whisper build) ==="
  echo ""
  for model in "${WHISPER_MODELS[@]}"; do
    IFS='|' read -r name repo file subdir <<< "$model"
    echo "  • $name"
    echo "    Repo: $repo"
    echo "    File: $file"
    echo ""
  done
}

download_model() {
  local name="$1"
  local repo="$2"
  local file_pattern="$3"
  local subdir="$4"

  echo "Downloading $name..."
  echo "  From: $repo"
  echo "  Pattern: $file_pattern"

  local output_dir="$MODELS_DIR/$subdir"
  mkdir -p "$output_dir"

  # Use huggingface-cli if available, otherwise wget
  if command -v huggingface-cli &>/dev/null; then
    huggingface-cli download "$repo" "$file_pattern" --local-dir "$output_dir" --local-dir-use-symlinks False
  else
    echo "  huggingface-cli not found, using wget..."
    # For wget, we need to construct the URL
    # This is a simplified approach - users should install huggingface-cli for better results
    local base_url="https://huggingface.co/$repo/resolve/main"
    local filename=$(echo "$file_pattern" | sed 's/\*//g')
    wget -P "$output_dir" "$base_url/$filename"
  fi

  echo "  ✓ Downloaded to $output_dir"
  echo ""
}

if [ "$LIST_ONLY" = true ]; then
  list_models
  exit 0
fi

# Check if models directory exists
if [ ! -d "$MODELS_DIR" ]; then
  echo "Creating models directory: $MODELS_DIR"
  sudo mkdir -p "$MODELS_DIR"
  sudo chown $USER:$USER "$MODELS_DIR"
fi

echo "Models will be downloaded to: $MODELS_DIR"
echo ""

# Interactive model selection
echo "Select models to download (space to select, enter to confirm):"
echo ""

PS3="Enter model number (or 'q' to quit): "
select model in "${MODELS[@]}" "Done"; do
  if [ "$REPLY" = "q" ]; then
    echo "Exiting..."
    exit 0
  fi

  if [ "$model" = "Done" ]; then
    echo "Finished selecting models."
    break
  fi

  IFS='|' read -r name repo file subdir <<< "$model"
  download_model "$name" "$repo" "$file" "$subdir"
done

echo ""
echo "=== Download Complete ==="
echo "Models downloaded to: $MODELS_DIR"
echo ""
echo "Next steps:"
echo "1. Edit your config.yaml to include the downloaded models"
echo "2. Update model paths to match: /models/<subdir>/<filename>"
echo "3. Restart the deployment: kubectl rollout restart deployment/llama-swappo-halo"
