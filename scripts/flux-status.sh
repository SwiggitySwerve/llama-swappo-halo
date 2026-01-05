#!/bin/bash
# Flux status helper - Show all Flux resources and status

set -e

echo "=== Flux Status ==="
echo ""

# Check if flux is installed
if ! command -v flux &> /dev/null; then
  echo "Error: Flux CLI not found. Install with:"
  echo "  curl -sL https://fluxcd.io/install.sh | sudo bash"
  exit 1
fi

# Check flux version
echo "Flux Version:"
flux version --short 2>/dev/null || echo "  Flux CLI installed but controllers not reachable"
echo ""

# Check flux pre-reqs
echo "=== Prerequisites Check ==="
flux check --pre
echo ""

# Git repositories
echo "=== Git Repositories ==="
flux get sources git
echo ""

# Image repositories
echo "=== Image Repositories ==="
flux get sources image 2>/dev/null || echo "  No image repositories configured"
echo ""

# Kustomizations
echo "=== Kustomizations ==="
flux get kustomizations
echo ""

# Helm releases (if any)
echo "=== Helm Releases ==="
flux get helmreleases 2>/dev/null || echo "  No Helm releases configured"
echo ""

# Conditions/Errors
echo "=== Ready Status ==="
kubectl get kustomizations -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[0].status 2>/dev/null || echo "  Unable to fetch status"
echo ""

# Recent errors
echo "=== Recent Errors (last 10) ==="
kubectl get events -n flux-system --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10 || echo "  No errors"
echo ""

# Pod status
echo "=== Flux System Pods ==="
kubectl get pods -n flux-system
