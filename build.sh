#!/bin/bash
# Build llama-swappo-halo container
#
# Usage:
#   ./build.sh              # Base LLM proxy
#   ./build.sh --stt        # With whisper STT (requires whisper-stt-rocm image)
#   ./build.sh --push       # Push to registry

set -e

CTR="${CONTAINER_CMD:-$(command -v nerdctl || command -v docker || command -v podman || echo docker)}"
IMAGE="${IMAGE_NAME:-llama-swappo-halo}"
TAG="latest"
CONTAINERFILE="Containerfile"

for arg in "$@"; do
    case $arg in
        --stt)
            CONTAINERFILE="Containerfile.stt"
            TAG="stt"
            ;;
        --push) PUSH=1 ;;
    esac
done

echo "Building $IMAGE:$TAG using $CTR"

$CTR build -f "$CONTAINERFILE" -t "$IMAGE:$TAG" .

[ "$PUSH" = "1" ] && $CTR push "$IMAGE:$TAG"

# Import to k3s if available
if command -v k3s &>/dev/null && [ "$CTR" != "docker" ]; then
    echo "Importing to k3s..."
    $CTR save "$IMAGE:$TAG" | sudo k3s ctr -n k8s.io images import - 2>/dev/null || true
fi

echo "Done: $IMAGE:$TAG"
