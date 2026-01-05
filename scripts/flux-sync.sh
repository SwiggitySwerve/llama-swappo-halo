#!/bin/bash
# Flux sync helper - Force immediate sync and show status

set -e

echo "=== Flux Sync Helper ==="
echo ""

# Check if flux is installed
if ! command -v flux &> /dev/null; then
  echo "Error: Flux CLI not found. Install with:"
  echo "  curl -sL https://fluxcd.io/install.sh | sudo bash"
  exit 1
fi

# Check if kubectl can connect
if ! kubectl get nodes &> /dev/null; then
  echo "Error: Cannot connect to k3s cluster. Check kubectl configuration."
  exit 1
fi

echo "Forcing immediate reconciliation..."
echo ""

# Reconcile with source
flux reconcile kustomization flux-system --with-source

echo ""
echo "Waiting for reconciliation to complete..."
sleep 3

echo ""
echo "=== Reconciliation Status ==="
flux get kustomizations

echo ""
echo "=== Recent Flux Events ==="
kubectl get events -n flux-system --sort-by='.lastTimestamp' | tail -10

echo ""
echo "=== Pod Status ==="
kubectl get pods -n flux-system
