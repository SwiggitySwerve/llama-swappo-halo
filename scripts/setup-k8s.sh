#!/bin/bash
# Setup script for llama-swappo-halo on k3s
# This script handles all operations that require elevated privileges

set -e

IMAGE_NAME="ghcr.io/mootikins/llama-swappo-halo:latest"
MODELS_DIR="/var/lib/llama-swappo/models"
CONFIG_DIR="/etc/llama-swappo"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== llama-swappo-halo k3s Setup ==="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges. Please run with sudo:"
  echo "  sudo $0"
  exit 1
fi

# Step 1: Fix kubectl config permissions
echo "=== Step 1: Fixing kubectl permissions ==="
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  chmod 644 /etc/rancher/k3s/k3s.yaml
  # Create user kubeconfig
  USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  mkdir -p "$USER_HOME/.kube"
  cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
  chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.kube"
  echo "✓ kubectl configured for user $SUDO_USER"
else
  echo "⚠ k3s.yaml not found. Make sure k3s is running."
fi
echo ""

# Step 2: Create necessary directories
echo "=== Step 2: Creating directories ==="
mkdir -p "$MODELS_DIR"
mkdir -p "$CONFIG_DIR"
chown -R "$SUDO_USER:$SUDO_USER" "$MODELS_DIR"
chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR"
echo "✓ Created: $MODELS_DIR"
echo "✓ Created: $CONFIG_DIR"
echo ""

# Step 3: Copy config file
echo "=== Step 3: Installing configuration ==="
if [ -f "$REPO_DIR/config/config.yaml" ]; then
  cp "$REPO_DIR/config/config.yaml" "$CONFIG_DIR/config.yaml"
  chown "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR/config.yaml"
  echo "✓ Installed config to $CONFIG_DIR/config.yaml"
else
  echo "⚠ Config file not found at $REPO_DIR/config/config.yaml"
  echo "  Please copy and customize config.yaml.example first"
fi
echo ""

# Step 4: Import container image to k3s
echo "=== Step 4: Importing container image to k3s ==="

# First check if image is already available in podman/docker
if command -v podman &>/dev/null; then
  echo "Pulling image with podman..."
  podman pull "$IMAGE_NAME"
  echo "Importing to k3s..."
  podman save "$IMAGE_NAME" --format docker-archive | k3s ctr -n k8s.io images import -
elif command -v docker &>/dev/null; then
  echo "Pulling image with docker..."
  docker pull "$IMAGE_NAME"
  echo "Importing to k3s..."
  docker save "$IMAGE_NAME" | k3s ctr -n k8s.io images import -
else
  echo "⚠ Neither podman nor docker found. Please pull the image manually:"
  echo "  sudo podman pull $IMAGE_NAME"
  echo "  sudo podman save $IMAGE_NAME | sudo k3s ctr -n k8s.io images import -"
fi

# Verify image import
if k3s ctr -n k8s.io images ls | grep -q "mootikins/llama-swappo-halo"; then
  echo "✓ Image imported successfully to k3s"
else
  echo "⚠ Image import may have failed. Please verify."
fi
echo ""

# Step 5: Deploy to k3s
echo "=== Step 5: Deploying to k3s ==="
if [ -f "$REPO_DIR/k8s/deployment.yaml" ] && [ -f "$REPO_DIR/k8s/service.yaml" ]; then
  kubectl apply -f "$REPO_DIR/k8s/"
  echo "✓ Kubernetes manifests applied"
else
  echo "⚠ Kubernetes manifests not found in $REPO_DIR/k8s/"
fi
echo ""

# Step 6: Verify deployment
echo "=== Step 6: Verifying deployment ==="
sleep 3
kubectl get pods -l app=llama-swappo-halo
echo ""
kubectl get svc -l app=llama-swappo-halo
echo ""

echo "=== Setup Complete ==="
echo ""
echo "Next steps (run as regular user):"
echo "1. Download models:"
echo "   ./scripts/download-models.sh --list"
echo "   ./scripts/download-models.sh --models-dir $MODELS_DIR"
echo ""
echo "2. Watch pod startup:"
echo "   kubectl logs -f deployment/llama-swappo-halo"
echo ""
echo "3. Test the API:"
echo "   curl http://localhost:8080/health"
echo "   curl http://localhost:8080/v1/models"
echo ""
echo "4. Edit config as needed:"
echo "   sudo nano $CONFIG_DIR/config.yaml"
echo "   kubectl rollout restart deployment/llama-swappo-halo"
