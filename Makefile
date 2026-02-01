.PHONY: help up down status check-prerequisites

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

check-prerequisites: ## Check if required tools are installed
	@echo "Checking prerequisites..."
	@command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is not installed. Please install Docker first."; exit 1; }
	@echo "✓ Docker is installed"
	@command -v ansible-playbook >/dev/null 2>&1 || { echo "ERROR: ansible is not installed. Please install Ansible: sudo apt install ansible -y"; exit 1; }
	@echo "✓ Ansible is installed"
	@test -n "$$GITHUB_TOKEN" || { echo "ERROR: GITHUB_TOKEN environment variable is not set."; echo "Please run: export GITHUB_TOKEN=<your-github-token>"; exit 1; }
	@echo "✓ GITHUB_TOKEN is set"
	@echo "All prerequisites are satisfied!"

up: check-prerequisites ## Bootstrap the kind cluster with Flux and all apps
	@echo "Bootstrapping superkube cluster..."
	ansible-playbook ansible/playbooks/bootstrap.yml

down: ## Destroy the kind cluster
	@echo "Destroying superkube cluster..."
	ansible-playbook ansible/playbooks/destroy.yml

status: ## Show cluster and Flux status
	@echo "=== Cluster Info ==="
	@kubectl cluster-info --context kind-superkube 2>/dev/null || echo "Cluster is not running"
	@echo ""
	@echo "=== Nodes ==="
	@kubectl get nodes --context kind-superkube 2>/dev/null || echo "No nodes found"
	@echo ""
	@echo "=== Flux System Pods ==="
	@kubectl get pods -n flux-system --context kind-superkube 2>/dev/null || echo "Flux is not installed"
	@echo ""
	@echo "=== Flux Kustomizations ==="
	@kubectl get kustomizations -A --context kind-superkube 2>/dev/null || echo "No kustomizations found"
	@echo ""
	@echo "=== Helm Releases ==="
	@kubectl get helmreleases -A --context kind-superkube 2>/dev/null || echo "No helm releases found"
	@echo ""
	@echo "=== Helm Repository Sources ==="
	@kubectl get helmrepositories -A --context kind-superkube 2>/dev/null || echo "No helm repositories found"
	@echo ""
	@echo "=== Application Pods ==="
	@echo "Ingress NGINX:"
	@kubectl get pods -n ingress-nginx --context kind-superkube 2>/dev/null || echo "  Not installed"
	@echo "Cert Manager:"
	@kubectl get pods -n cert-manager --context kind-superkube 2>/dev/null || echo "  Not installed"
	@echo "Metrics Server:"
	@kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server --context kind-superkube 2>/dev/null || echo "  Not installed"
