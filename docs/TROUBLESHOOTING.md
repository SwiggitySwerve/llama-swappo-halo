# Troubleshooting Guide

This guide covers common issues and their solutions for llama-swappo-halo.

## Table of Contents

- [Deployment Issues](#deployment-issues)
  - [Pod Stuck in Pending State](#pod-stuck-in-pending-state)
  - [Port Conflicts with hostNetwork](#port-conflicts-with-hostnetwork)
- [Model Discovery Issues](#model-discovery-issues)
- [Permission Issues](#permission-issues)
- [Flux GitOps Issues](#flux-gitops-issues)
- [Performance Issues](#performance-issues)

---

## Deployment Issues

### Pod Stuck in Pending State

**Symptoms:**
```bash
$ kubectl get pods -l app=llama-swappo-halo
NAME                                 READY   STATUS    RESTARTS   AGE
llama-swappo-halo-5bd986f7d6-jwq6h   1/1     Running   0          5h
llama-swappo-halo-78bd856fd9-xw8sw   0/1     Pending   0          10m
```

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod -l app=llama-swappo-halo | grep -A 10 "Events:"
```

**Error message:**
```
Warning  FailedScheduling  0/1 nodes are available: 1 node(s) didn't have free ports
for the requested pod ports. preemption: 0/1 nodes are available: 1 No preemption
victims found for incoming pod.
```

**Root Cause:**
- The deployment uses `hostNetwork: true` to bind directly to host port 8080
- Two pods cannot bind to the same host port simultaneously
- Old pod is still running, blocking the new pod from starting

**Solution 1: Automatic (Deployment Fixed)** ✅ **RECOMMENDED**

The deployment now uses `strategy: Recreate` which automatically handles this:

```yaml
spec:
  strategy:
    type: Recreate  # Terminates old pod before starting new one
```

This prevents the issue but causes ~30 seconds of downtime during updates.

**Solution 2: Manual Intervention (If Issue Still Occurs)**

If the old pod doesn't terminate automatically:

```bash
# 1. Delete the old pod manually
kubectl delete pod -l app=llama-swappo-halo --field-selector status.phase=Running

# 2. Verify new pod starts
kubectl get pods -l app=llama-swappo-halo -w

# 3. Wait for pod to be ready (may take 30-60 seconds)
kubectl wait --for=condition=ready pod -l app=llama-swappo-halo --timeout=120s

# 4. Verify service is accessible
curl http://localhost:8080/health
```

**Solution 3: Prevent the Issue Entirely**

Alternative deployment strategies if you don't need `hostNetwork: true`:

**Option A: Use NodePort instead of hostNetwork**
```yaml
spec:
  # Remove: hostNetwork: true
  containers:
  - name: llama-swappo-halo
    ports:
    - containerPort: 8080
---
apiVersion: v1
kind: Service
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080  # Access via http://node-ip:30080
```

**Option B: Use RollingUpdate with strict settings**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
```

---

### Port Conflicts with hostNetwork

**Why We Use hostNetwork:**
- Direct LAN access without NodePort
- Simpler networking for single-node k3s cluster
- No additional port mapping needed

**Trade-offs:**
- Only one pod can run per node (port 8080 conflict)
- Requires `Recreate` deployment strategy
- Brief downtime (~30s) during updates
- Pod scheduling constraints on multi-node clusters

**Alternative Architectures:**

If you need zero-downtime deployments, consider:

1. **Remove hostNetwork + Use Ingress**
   ```yaml
   # deployment.yaml
   spec:
     # Remove hostNetwork: true
     replicas: 2  # Can now run multiple replicas

   # ingress.yaml (requires ingress controller)
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   spec:
     rules:
     - host: llama.example.com
       http:
         paths:
         - path: /
           backend:
             service:
               name: llama-swappo-halo
               port: 8080
   ```

2. **Use External Load Balancer**
   - HAProxy or nginx on host
   - Proxy port 8080 to Kubernetes service
   - Enables rolling updates without downtime

---

## Model Discovery Issues

### Only Seeing 2 Models Instead of 5

**Symptoms:**
```bash
$ curl -s http://localhost:8080/v1/models | jq -r '.data[] | .id' | sort
deepseek-coder-v2-lite-instruct-q4_k_m
qwen2.5-coder-7b-instruct-q5_k_m
# Missing: qwen2.5-coder-3b, qwen2.5-coder-32b, gpt-oss-20b
```

**Root Cause:**
- Pod is running with stale configuration
- ConfigMap was updated but pod wasn't restarted

**Solution:**

```bash
# 1. Verify ConfigMap has all 5 models
kubectl get configmap llama-swappo-halo-config -o yaml | grep -A 5 "models:"

# 2. Restart deployment to pick up config
kubectl rollout restart deployment/llama-swappo-halo

# 3. Wait for new pod to be ready
kubectl rollout status deployment/llama-swappo-halo

# 4. Verify all 5 models are discovered
curl -s http://localhost:8080/v1/models | jq -r '.data[] | .id' | sort
```

**Expected Output (5 models):**
```
deepseek-coder-v2-lite-instruct-q4_k_m
gpt-oss-20b-q8_k_xl
qwen2.5-coder-32b-instruct-q5_k_m
qwen2.5-coder-3b-instruct-q4_k_m
qwen2.5-coder-7b-instruct-q5_k_m
```

### Models Failing to Load

**Symptoms:**
- Models listed in `/v1/models` but return errors when used
- Logs show "failed to load model" errors

**Diagnosis:**
```bash
# Check pod logs for errors
kubectl logs -f deployment/llama-swappo-halo | grep -i error

# Verify model files exist
kubectl exec deployment/llama-swappo-halo -- ls -lh /models/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/

# Check model file permissions
kubectl exec deployment/llama-swappo-halo -- stat /models/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/qwen2.5-coder-7b-instruct-q5_k_m.gguf
```

**Common Causes:**

1. **Incorrect model paths in config**
   ```bash
   # Verify path matches ConfigMap
   kubectl exec deployment/llama-swappo-halo -- cat /app/config.yaml | grep -A 3 "qwen2.5-coder-7b"
   ```

2. **Missing model files**
   ```bash
   # Check if model was downloaded
   ls -lh /var/lib/llama-swappo/models/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/

   # Download missing models
   ./scripts/download-models.sh --models-dir /var/lib/llama-swappo/models
   ```

3. **Insufficient memory**
   ```bash
   # Check memory limits
   kubectl describe pod -l app=llama-swappo-halo | grep -A 5 "Limits:"

   # Large models (32B) may need 32Gi+ memory
   ```

---

## Permission Issues

### kubectl Permission Denied

**Symptoms:**
```bash
$ kubectl get pods
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
```

**Solution:**

```bash
# 1. Copy kubeconfig to user directory (requires sudo once)
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# 2. Fix ownership
sudo chown $USER:$USER ~/.kube/config

# 3. Set proper permissions
chmod 600 ~/.kube/config

# 4. Export KUBECONFIG environment variable
export KUBECONFIG=~/.kube/config

# 5. Make it persistent (add to ~/.bashrc)
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc

# 6. Test access
kubectl get pods
```

---

## Flux GitOps Issues

### Flux Not Syncing Changes

**Symptoms:**
- Git commits not reflected in cluster
- `flux get kustomizations` shows old revision

**Diagnosis:**
```bash
# Check Flux status
flux check

# Check kustomization status
flux get kustomizations

# Check source status
flux get sources git
```

**Solution:**

```bash
# Force immediate reconciliation
flux reconcile kustomization flux-system --with-source

# Watch for updates
flux get kustomizations --watch

# Check Flux logs for errors
kubectl logs -n flux-system deployment/source-controller
kubectl logs -n flux-system deployment/kustomize-controller
```

### ConfigMap Changes Not Applied

**Important:** ConfigMap changes alone do NOT trigger pod restarts in Kubernetes.

**Workflow:**

```bash
# 1. Edit ConfigMap
vim k8s/flux/configmap.yaml

# 2. Commit and push
git add k8s/flux/configmap.yaml
git commit -m "feat: update model configuration"
git push

# 3. Update deployment annotation to trigger restart
vim k8s/flux/deployment.yaml
# Change: config-version: "2026-01-05-new-config"

git add k8s/flux/deployment.yaml
git commit -m "chore: trigger config reload"
git push

# 4. Force Flux sync
flux reconcile kustomization flux-system --with-source

# 5. Verify changes applied
kubectl get configmap llama-swappo-halo-config -o yaml
kubectl get pods -l app=llama-swappo-halo
```

---

## Performance Issues

### Slow Model Inference

**Check CPU-only vs GPU:**

Current setup uses CPU-only mode due to Strix Halo GPU issues.

```bash
# Verify CPU-only mode in config
kubectl exec deployment/llama-swappo-halo -- cat /app/config.yaml | grep -A 2 "HIP_VISIBLE_DEVICES"

# Should show:
# env:
#   - "HIP_VISIBLE_DEVICES=-1"  # Hide GPU
# --n-gpu-layers 0  # Force CPU
```

**Optimization Tips:**

1. **Use smaller models for faster inference:**
   - 3B model: Fastest, good for simple tasks
   - 7B model: Balanced performance/quality
   - 32B model: Slowest, best quality

2. **Adjust thread count:**
   ```yaml
   # In macros section of ConfigMap
   macros:
     "llama": >
       --threads 8  # Increase for faster CPU inference
   ```

3. **Monitor resource usage:**
   ```bash
   # Check CPU/memory usage
   kubectl top pod -l app=llama-swappo-halo
   ```

### High Memory Usage

**Symptoms:**
- Pod being OOMKilled
- Slow swap thrashing

**Solutions:**

1. **Increase memory limits:**
   ```yaml
   # In deployment.yaml
   resources:
     limits:
       memory: "64Gi"  # Increase for large models
   ```

2. **Use smaller quantized models:**
   - Q4_K_M: Lower memory, slightly reduced quality
   - Q5_K_M: Balanced
   - Q8_K_XL: Higher memory, best quality

3. **Enable model swapping:**
   Models in the same group with `swap: true` automatically unload when switching.

---

## Additional Resources

- **Main Documentation**: [CLAUDE.md](../CLAUDE.md)
- **Quick Start Guide**: [QUICKSTART.md](../QUICKSTART.md)
- **API Usage**: [API_USAGE_GUIDE.md](../API_USAGE_GUIDE.md)
- **Strix Halo CPU-only Mode**: [STRIX_HALLO_CPU_ONLY.md](../STRIX_HALLO_CPU_ONLY.md)

---

## Getting Help

If issues persist:

1. Check logs: `./scripts/k8s-logs.sh`
2. Check Flux status: `./scripts/flux-status.sh`
3. Review recent commits: `git log --oneline -10`
4. File an issue with:
   - Pod logs
   - `kubectl describe pod` output
   - ConfigMap contents
   - Error messages
