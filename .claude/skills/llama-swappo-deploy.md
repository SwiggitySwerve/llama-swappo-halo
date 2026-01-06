---
name: llama-swappo-deploy
description: Manage llama-swappo-halo Kubernetes deployment, handle restarts, Flux GitOps operations, and resolve port conflicts with hostNetwork. Use when deploying, restarting, troubleshooting pods, or syncing configuration changes.
---

# llama-swappo-halo Deployment Management

This skill handles Kubernetes deployment operations for llama-swappo-halo, a containerized LLM proxy running on k3s with Flux CD GitOps automation.

## When to Use This Skill

Use this skill when the user requests:
- Restarting the llama-swappo-halo deployment
- Forcing Flux to sync changes from Git
- Troubleshooting pods stuck in Pending state
- Applying configuration changes
- Resolving port 8080 conflicts with hostNetwork
- Checking deployment status

## Architecture Context

**Key Deployment Characteristics:**
- Uses `hostNetwork: true` for direct LAN access on port 8080
- Deployment strategy: `Recreate` (prevents port conflicts, ~30s downtime)
- Configuration via ConfigMap: `llama-swappo-halo-config`
- GitOps managed: Flux CD syncs from Git every 5 minutes
- Single replica (port 8080 can only bind once per node)

**Critical Constraint:** With `hostNetwork: true`, two pods cannot run simultaneously on the same node due to port 8080 conflicts.

## Prerequisites

Ensure KUBECONFIG is set:
```bash
export KUBECONFIG=~/.kube/config
```

If kubectl returns permission errors, run:
```bash
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
```

## Deployment Restart Methods

### Method 1: Quick Manual Restart (Recommended)

For immediate restarts when configuration hasn't changed:

```bash
# Delete pod to trigger recreation (Recreate strategy)
kubectl delete pod -l app=llama-swappo-halo

# Watch pod restart
kubectl get pods -l app=llama-swappo-halo -w

# Verify health
curl http://localhost:8080/health
```

### Method 2: GitOps Restart via Annotation Change

For configuration changes that need to be tracked in Git:

```bash
# 1. Edit deployment annotation in k8s/flux/deployment.yaml
# Change config-version to unique value:
#   annotations:
#     config-version: "2026-01-05-descriptive-change"

# 2. Commit and push
git add k8s/flux/deployment.yaml
git commit -m "chore: trigger deployment restart for config update"
git push origin main

# 3. Force Flux to sync immediately
flux reconcile kustomization flux-system --with-source

# 4. Monitor rollout
kubectl get pods -l app=llama-swappo-halo -w
```

### Method 3: ConfigMap Update Workflow

When updating model configurations:

```bash
# 1. Edit ConfigMap
vim k8s/flux/configmap.yaml

# 2. Commit ConfigMap changes
git add k8s/flux/configmap.yaml
git commit -m "feat: update model configuration"
git push

# 3. Update deployment annotation (triggers restart)
vim k8s/flux/deployment.yaml
# Change: config-version: "2026-01-05-model-config-update"

git add k8s/flux/deployment.yaml
git commit -m "chore: trigger config reload"
git push

# 4. Force Flux sync
flux reconcile kustomization flux-system --with-source
```

**Important:** ConfigMap changes alone do NOT trigger pod restarts. You must update the deployment annotation.

## Troubleshooting Port Conflicts

### Symptom: Pod Stuck in Pending State

```bash
$ kubectl get pods -l app=llama-swappo-halo
NAME                                 READY   STATUS    RESTARTS   AGE
llama-swappo-halo-5bd986f7d6-jwq6h   1/1     Running   0          5h
llama-swappo-halo-78bd856fd9-xw8sw   0/1     Pending   0          10m
```

### Diagnosis

```bash
# Check for scheduling errors
kubectl describe pod -l app=llama-swappo-halo | grep -A 5 "Events:"
```

**Expected error message:**
```
Warning  FailedScheduling  0/1 nodes are available: 1 node(s) didn't have free ports
for the requested pod ports.
```

### Solution: Manual Pod Deletion

The `Recreate` strategy should prevent this, but if it occurs:

```bash
# 1. Identify running pod
kubectl get pods -l app=llama-swappo-halo

# 2. Delete old pod (forces new one to start)
kubectl delete pod <old-pod-name>
# OR delete by label:
kubectl delete pod -l app=llama-swappo-halo --field-selector status.phase=Running

# 3. Wait for new pod
kubectl wait --for=condition=ready pod -l app=llama-swappo-halo --timeout=120s

# 4. Verify service
curl http://localhost:8080/health
```

## Verification Steps

After any deployment operation, verify:

```bash
# 1. Check pod status
kubectl get pods -l app=llama-swappo-halo

# 2. Check deployment status
kubectl get deployment llama-swappo-halo

# 3. Verify health endpoint
curl http://localhost:8080/health

# 4. List available models (should show 5)
curl -s http://localhost:8080/v1/models | jq -r '.data[] | .id' | sort

# Expected models:
# deepseek-coder-v2-lite-instruct-q4_k_m
# gpt-oss-20b-q8_k_xl
# qwen2.5-coder-32b-instruct-q5_k_m
# qwen2.5-coder-3b-instruct-q4_k_m
# qwen2.5-coder-7b-instruct-q5_k_m
```

## Flux GitOps Operations

### Check Flux Status

```bash
# Overall Flux health
flux check

# Kustomization status
flux get kustomizations

# Git source status
flux get sources git

# Image repository status (for auto-updates)
flux get image repository
flux get image policy
```

### Force Immediate Sync

```bash
# Sync entire Flux system
flux reconcile kustomization flux-system --with-source

# Watch for updates
flux get kustomizations --watch
```

### View Flux Logs

```bash
# All Flux controllers
./scripts/k8s-logs.sh --flux

# Specific controller
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/kustomize-controller
kubectl logs -n flux-system deployment/image-reflector-controller
```

## Common Pitfalls

1. **Forgetting to update deployment annotation after ConfigMap changes**
   - ConfigMap updates won't trigger pod restart
   - Solution: Always update `config-version` annotation

2. **Not waiting for Flux to sync before checking**
   - Flux syncs every 5 minutes by default
   - Solution: Use `flux reconcile` for immediate sync

3. **Port conflicts with multiple pods**
   - Old pod blocks new pod from starting
   - Solution: `Recreate` strategy handles this, but manual deletion may be needed

4. **Not exporting KUBECONFIG**
   - kubectl permission errors
   - Solution: `export KUBECONFIG=~/.kube/config`

## Workflow Summary

**Standard deployment restart:**
1. Make changes to `k8s/flux/configmap.yaml` and/or `k8s/flux/deployment.yaml`
2. Update `config-version` annotation in deployment
3. Commit and push to Git
4. Run `flux reconcile kustomization flux-system --with-source`
5. Verify pod restarts and service is healthy

**Emergency restart:**
1. `kubectl delete pod -l app=llama-swappo-halo`
2. Wait for pod to be ready
3. Test service

**Troubleshooting stuck pod:**
1. Check events: `kubectl describe pod -l app=llama-swappo-halo`
2. If port conflict, delete old pod manually
3. Verify new pod starts successfully
