# Kubernetes Manifests for llama-swappo-halo

This directory contains Kubernetes manifests for deploying llama-swappo-halo to k3s with Flux CD GitOps automation.

## Directory Structure

```
k8s/
├── flux/                    # Flux CD managed manifests
│   ├── kustomization.yaml  # Kustomize definition
│   ├── deployment.yaml     # Deployment resource
│   ├── service.yaml        # Service resource
│   ├── image-repository.yaml    # Image automation config
│   └── image-policy.yaml         # Image update policy
└── base/                   # Reference manifests (optional)
```

## Flux CD GitOps

The `flux/` directory is managed by Flux CD. When you push changes to these files, Flux automatically applies them to the cluster.

### How It Works

1. **Flux controllers** run in the `flux-system` namespace
2. **GitRepository resource** watches this GitHub repository
3. **Kustomization resource** applies manifests from `./k8s/flux`
4. **Automatic sync** happens every 1 minute (configurable)

### Making Changes

1. Edit manifests in `k8s/flux/`
2. Commit and push to GitHub:
   ```bash
   git add k8s/flux/
   git commit -m "Update deployment"
   git push
   ```
3. Flux automatically applies changes within 1 minute
4. Or force immediate sync:
   ```bash
   ./scripts/flux-sync.sh
   ```

## Resources

### Deployment (`deployment.yaml`)

Defines the llama-swappo-halo deployment:

- **Image**: `ghcr.io/mootikins/llama-swappo-halo:latest`
- **Port**: 8080 (hostNetwork enabled)
- **GPU Access**: Privileged container with `/dev/dri` and `/dev/kfd` mounts
- **Volumes**:
  - `/var/lib/llama-swappo/models` → `/models` (read-only)
  - `/etc/llama-swappo/config.yaml` → `/app/config.yaml` (read-only)

### Service (`service.yaml`)

ClusterIP service for internal cluster access:

- **Type**: ClusterIP
- **Port**: 8080
- **Selector**: `app=llama-swappo-halo`

### Image Automation

- **image-repository.yaml**: Watches `ghcr.io/mootikins/llama-swappo-halo` for new images
- **image-policy.yaml**: Defines semver range for automatic updates

To enable image automation, update the deployment image reference:
```yaml
image: ghcr.io/mootikins/llama-swappo-halo:# {"$imagepolicy": "flux-system:llama-swappo-halo-latest:tag"}
```

## Adding New Applications

To add more applications to this Flux setup:

1. Create new manifest files in `k8s/flux/`
2. Add them to `kustomization.yaml`:
   ```yaml
   resources:
     - deployment.yaml
     - service.yaml
     - your-new-app.yaml  # Add here
   ```
3. Commit and push

## Examples

### Update Replicas

Edit `k8s/flux/deployment.yaml`:
```yaml
spec:
  replicas: 3  # Change from 1 to 3
```

### Change Memory Limits

Edit `k8s/flux/deployment.yaml`:
```yaml
resources:
  limits:
    memory: "64Gi"  # Increase from 32Gi
```

### Add Environment Variable

Edit `k8s/flux/deployment.yaml`:
```yaml
env:
  - name: LD_LIBRARY_PATH
    value: "/app/lib:$(LD_LIBRARY_PATH)"
  - name: NEW_VAR
    value: "value"
```

## Troubleshooting

### Check if Flux Applied Changes

```bash
# View live deployment
kubectl get deployment llama-swappo-halo -o yaml

# Compare with Git
git diff HEAD k8s/flux/deployment.yaml
```

### Manual Rollback

```bash
# Revert last commit
git revert HEAD

# Push revert
git push

# Flux auto-applies the revert
```

### Force Reconciliation

```bash
# Force Flux to sync immediately
flux reconcile kustomization flux-system --with-source

# Watch the reconciliation
flux get kustomizations --watch
```

## Best Practices

1. **Always edit files in `k8s/flux/`**, not live cluster resources
2. **Commit messages should be descriptive** for audit trail
3. **Test changes in a branch first** before merging to main
4. **Use image tags** instead of `latest` for production
5. **Monitor Flux logs** after applying changes:
   ```bash
   ./scripts/k8s-logs.sh --flux
   ```

## See Also

- [Main README](../README.md) - Project overview and quick start
- [Flux CD Documentation](https://fluxcd.io/flux/) - Official Flux docs
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
