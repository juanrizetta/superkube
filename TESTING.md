# Testing Superkube

This document provides testing instructions for the Superkube setup.

## Prerequisites for Testing

Before testing, ensure you have:

1. **Docker installed and running**
   ```bash
   docker --version
   sudo systemctl start docker
   sudo usermod -aG docker $USER
   # Log out and back in for group changes to take effect
   ```

2. **Ansible installed**
   ```bash
   sudo apt update
   sudo apt install ansible -y
   ansible --version
   ```

3. **GitHub Personal Access Token**
   ```bash
   # Create token at: https://github.com/settings/tokens
   # Required scopes: repo (full control)
   export GITHUB_TOKEN=<your-token>
   ```

## Test Plan

### 1. Validate Configuration Files

#### Test Kubernetes Manifests
```bash
# Validate gitops kustomization
cd gitops
kubectl kustomize .

# Should output all Kubernetes manifests without errors
```

#### Test Ansible Playbooks
```bash
# Check syntax
ansible-playbook --syntax-check ansible/playbooks/bootstrap.yml
ansible-playbook --syntax-check ansible/playbooks/destroy.yml

# Should show no syntax errors
```

#### Test Makefile
```bash
make help
# Should display all available commands
```

### 2. Test Prerequisites Check

```bash
make check-prerequisites
```

Expected:
- Should verify Docker is installed
- Should verify Ansible is installed
- Should verify GITHUB_TOKEN is set
- If any missing, should show clear error messages

### 3. Full Bootstrap Test

```bash
# Set the GitHub token
export GITHUB_TOKEN=<your-token>

# Bootstrap the cluster
make up
```

Expected sequence:
1. Prerequisites verification
2. Tool installation (kubectl, kind, flux, helm if needed)
3. Kind cluster creation (~30 seconds)
4. Cluster ready confirmation
5. Flux bootstrap (~2-3 minutes)
6. GitOps reconciliation begins

Expected output should include:
```
TASK [Display bootstrap completion message]
ok: [localhost] => {
    "msg": [
        "Bootstrap completed successfully!",
        "Cluster: superkube",
        "Flux is reconciling from: juanrizetta/superkube/clusters/dev",
        ...
    ]
}
```

### 4. Verify Installation

```bash
make status
```

Expected output:
- **Cluster Info**: Should show running cluster
- **Nodes**: 1 control-plane node in Ready state
- **Flux System Pods**: All pods Running
- **Flux Kustomizations**: flux-system and superkube-apps Ready
- **Helm Releases**: ingress-nginx, cert-manager, metrics-server Ready
- **Helm Repository Sources**: All Ready
- **Application Pods**: All Running in respective namespaces

### 5. Manual Verification

#### Check Flux Status
```bash
kubectl get pods -n flux-system
# All pods should be Running

flux get sources git -A
# GitRepository should be Ready

flux get kustomizations -A
# All Kustomizations should be Ready

flux get helmreleases -A
# All HelmReleases should be Ready
```

#### Check Application Pods
```bash
# Ingress NGINX
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Cert Manager
kubectl get pods -n cert-manager
kubectl get crds | grep cert-manager

# Metrics Server
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
kubectl top nodes
```

#### Test Ingress Functionality
```bash
# Check if ports are accessible
curl -k http://localhost
# Should return 404 from ingress-nginx (no backend configured yet)

curl -k https://localhost
# Should return 404 from ingress-nginx (no backend configured yet)
```

### 6. Test GitOps Reconciliation

#### Trigger Manual Reconciliation
```bash
flux reconcile kustomization flux-system --with-source
flux reconcile kustomization superkube-apps --with-source
flux reconcile helmrelease ingress-nginx -n flux-system
```

#### Verify Automatic Reconciliation
```bash
# Make a change to a HelmRelease (e.g., add a label)
# Commit and push to GitHub
# Wait 10 minutes or force reconcile
# Verify the change is applied in the cluster
```

### 7. Test Cluster Destruction

```bash
make down
```

Expected:
- Cluster deletion confirmation
- All resources cleaned up
- Kind cluster no longer listed

Verify:
```bash
kind get clusters
# Should not list 'superkube'

docker ps
# Should not show superkube containers
```

### 8. Test Idempotency

```bash
# Run bootstrap twice
make up
make up  # Should skip already created resources

# Verify no errors on second run
```

### 9. Test Recovery

```bash
# Create cluster
make up

# Manually delete a pod
kubectl delete pod -n ingress-nginx --all

# Wait for Flux to reconcile
sleep 30

# Verify pod is recreated
kubectl get pods -n ingress-nginx
# Pods should be Running again
```

## Common Issues and Solutions

### Issue: Port 80 or 443 already in use
```bash
# Find what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Stop the conflicting service
sudo systemctl stop apache2  # Example
```

### Issue: Docker permission denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: Flux bootstrap fails
```bash
# Check GitHub token
echo $GITHUB_TOKEN

# Verify token has correct permissions
# Token needs 'repo' scope

# Check network connectivity
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### Issue: HelmRelease fails to install
```bash
# Check Helm controller logs
kubectl logs -n flux-system -l app=helm-controller -f

# Describe the HelmRelease
kubectl describe helmrelease <name> -n flux-system

# Check HelmRepository is Ready
kubectl get helmrepositories -A
```

### Issue: Pods in CrashLoopBackOff
```bash
# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Describe pod for events
kubectl describe pod -n <namespace> <pod-name>

# For metrics-server in kind, ensure insecure TLS flag is set
kubectl get helmrelease metrics-server -n flux-system -o yaml | grep kubelet-insecure-tls
```

## Automated Testing Script

Create this script for automated testing:

```bash
#!/bin/bash
set -e

echo "=== Superkube Automated Test ==="

# Prerequisites
echo "Checking prerequisites..."
docker --version
ansible --version
test -n "$GITHUB_TOKEN" || { echo "ERROR: GITHUB_TOKEN not set"; exit 1; }

# Validate manifests
echo "Validating Kubernetes manifests..."
cd gitops && kubectl kustomize . > /dev/null && cd ..

# Validate Ansible
echo "Validating Ansible playbooks..."
ansible-playbook --syntax-check ansible/playbooks/bootstrap.yml
ansible-playbook --syntax-check ansible/playbooks/destroy.yml

# Bootstrap
echo "Bootstrapping cluster..."
make up

# Wait for reconciliation
echo "Waiting for reconciliation..."
sleep 120

# Verify
echo "Verifying installation..."
kubectl wait --for=condition=ready --timeout=300s --all pods -n flux-system
kubectl wait --for=condition=ready --timeout=300s --all pods -n ingress-nginx
kubectl wait --for=condition=ready --timeout=300s --all pods -n cert-manager

# Status
echo "Checking status..."
make status

# Cleanup
echo "Cleaning up..."
make down

echo "=== All tests passed! ==="
```

## Performance Benchmarks

Expected timings on a typical Ubuntu machine:

- **Bootstrap (first run)**: 5-10 minutes
  - Tool installation: 2-3 minutes
  - Cluster creation: 30-60 seconds
  - Flux bootstrap: 2-3 minutes
  - Application deployment: 2-4 minutes

- **Bootstrap (subsequent runs)**: 3-5 minutes
  - Tools already installed
  - Cluster creation: 30-60 seconds
  - Flux reconciliation: 2-4 minutes

- **Status check**: < 5 seconds

- **Cluster destruction**: 10-20 seconds

## Test Results Template

```
# Superkube Test Results

Date: YYYY-MM-DD
Tester: [Name]
Environment: [Ubuntu version, Docker version]

## Test Results

| Test Case | Status | Duration | Notes |
|-----------|--------|----------|-------|
| Validate manifests | PASS/FAIL | Xs | |
| Prerequisites check | PASS/FAIL | Xs | |
| Bootstrap cluster | PASS/FAIL | Xm | |
| Verify installation | PASS/FAIL | Xs | |
| Flux reconciliation | PASS/FAIL | Xm | |
| Destroy cluster | PASS/FAIL | Xs | |
| Idempotency test | PASS/FAIL | Xm | |

## Issues Found

1. [Description of any issues]

## Overall Result

[ ] All tests passed
[ ] Some tests failed (see issues above)
```
