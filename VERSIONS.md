# Component Versions

This document tracks the versions of all components in the Superkube stack.

## Infrastructure Tools

| Tool | Version | Installation Method | Notes |
|------|---------|-------------------|-------|
| kind | 0.20.0 | Auto-installed | Kubernetes in Docker |
| kubectl | 1.28.0 | Auto-installed | Kubernetes CLI |
| flux | 2.2.0 | Auto-installed | GitOps toolkit |
| helm | 3.x (latest) | Auto-installed | Package manager |

## Kubernetes Components

| Component | Chart Version | App Version | Repository |
|-----------|--------------|-------------|------------|
| ingress-nginx | 4.8.3 | 1.9.4 | https://kubernetes.github.io/ingress-nginx |
| cert-manager | v1.13.3 | v1.13.3 | https://charts.jetstack.io |
| metrics-server | 3.11.0 | 0.6.4 | https://kubernetes-sigs.github.io/metrics-server/ |

## Flux Components

Flux is installed via `flux bootstrap github` which automatically installs:
- source-controller
- kustomize-controller
- helm-controller
- notification-controller

Version: 2.2.0 (pinned in bootstrap playbook)

## Upgrade Guide

### Upgrading Helm Charts

1. **Check for new versions:**
   ```bash
   # Add the Helm repositories
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo add jetstack https://charts.jetstack.io
   helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
   helm repo update

   # Search for versions
   helm search repo ingress-nginx/ingress-nginx --versions | head
   helm search repo jetstack/cert-manager --versions | head
   helm search repo metrics-server/metrics-server --versions | head
   ```

2. **Update the version in the HelmRelease:**
   - Edit `gitops/releases/<component>.yaml`
   - Change the `version` field
   - Commit and push

3. **Monitor the upgrade:**
   ```bash
   flux reconcile helmrelease <name> -n flux-system
   kubectl get helmreleases -A -w
   ```

### Upgrading Infrastructure Tools

#### kind
```bash
# Check current version
kind version

# Download new version
curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.21.0/kind-linux-amd64
sudo install -m 0755 /tmp/kind /usr/local/bin/kind

# Update version in bootstrap.yml
# Recreate cluster with: make down && make up
```

#### kubectl
```bash
# Check current version
kubectl version --client

# Download new version
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl

# Update version in bootstrap.yml
```

#### Flux
```bash
# Check current version
flux version

# Upgrade CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Upgrade in-cluster components
flux install --export > /tmp/flux-components.yaml
kubectl apply -f /tmp/flux-components.yaml
```

## Version Compatibility Matrix

| Kubernetes | kind | kubectl | Flux | Helm |
|------------|------|---------|------|------|
| 1.28.x | 0.20.0 | 1.28.x | 2.2.0 | 3.x |
| 1.29.x | 0.21.0+ | 1.29.x | 2.2.0+ | 3.x |

## Chart Version History

### ingress-nginx
- **4.8.3** (current) - Nov 2023
  - App version: 1.9.4
  - Improvements: Better kind support, stability fixes

Previous versions:
- 4.8.0 - Oct 2023
- 4.7.0 - Aug 2023

### cert-manager
- **v1.13.3** (current) - Dec 2023
  - App version: v1.13.3
  - Improvements: Bug fixes, security updates

Previous versions:
- v1.13.0 - Sep 2023
- v1.12.0 - May 2023

### metrics-server
- **3.11.0** (current) - Aug 2023
  - App version: 0.6.4
  - Improvements: Performance improvements

Previous versions:
- 3.10.0 - May 2023
- 3.9.0 - Feb 2023

## Testing New Versions

Before upgrading production:

1. Test in a separate cluster:
   ```bash
   # Create test environment
   export GITHUB_TOKEN=<token>
   make up
   ```

2. Update one component at a time

3. Verify functionality:
   ```bash
   make status
   kubectl get all -A
   ```

4. Monitor for issues:
   ```bash
   kubectl get events -A --sort-by='.lastTimestamp'
   flux logs --follow
   ```

## Deprecation Notices

### Current
- None at this time

### Upcoming
- Flux v2beta1 APIs will eventually be replaced with v2 (no specific timeline)
- kind may change default Kubernetes version in future releases

## Security Updates

Check these sources regularly for security updates:

- [Kubernetes CVEs](https://kubernetes.io/docs/reference/issues-security/official-cve-feed/)
- [ingress-nginx Security](https://github.com/kubernetes/ingress-nginx/security/advisories)
- [cert-manager Security](https://github.com/cert-manager/cert-manager/security/advisories)
- [Flux Security](https://github.com/fluxcd/flux2/security/advisories)

## Update Schedule

Recommended update schedule:

- **Weekly**: Check for security advisories
- **Monthly**: Check for new patch versions
- **Quarterly**: Consider minor version upgrades
- **Annually**: Plan major version upgrades

## Rollback Procedures

If an upgrade fails:

1. **Revert the HelmRelease version:**
   ```bash
   git revert <commit-hash>
   git push
   ```

2. **Force reconciliation:**
   ```bash
   flux reconcile kustomization superkube-apps --with-source
   ```

3. **If cluster is broken:**
   ```bash
   make down
   git checkout <working-commit>
   make up
   ```

## Notes

- All versions are pinned explicitly for reproducibility
- Automatic updates are disabled - all upgrades are manual
- Version changes should be tested before production deployment
- Keep this document updated when versions change
