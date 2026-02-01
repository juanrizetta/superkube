# Contributing to Superkube

Thank you for your interest in contributing to Superkube! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the best outcome for the project

## How to Contribute

### Reporting Bugs

If you find a bug:

1. Check if the issue already exists in GitHub Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version, etc.)
   - Relevant logs or error messages

### Suggesting Enhancements

To suggest a new feature:

1. Check existing issues to avoid duplicates
2. Create an issue describing:
   - The problem you're trying to solve
   - Your proposed solution
   - Alternative solutions considered
   - Any relevant examples or mockups

### Pull Requests

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow existing code style
   - Keep changes focused and minimal
   - Add/update documentation as needed

4. **Test your changes**
   ```bash
   # Validate manifests
   kubectl kustomize gitops/

   # Check Ansible syntax
   ansible-playbook --syntax-check ansible/playbooks/*.yml

   # Test the full setup
   make down  # Clean slate
   make up    # Bootstrap
   make status  # Verify
   ```

5. **Commit your changes**
   ```bash
   git commit -m "feat: add new feature"
   ```

   Use conventional commit format:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `chore:` - Maintenance tasks
   - `refactor:` - Code refactoring
   - `test:` - Test changes

6. **Push and create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

   Then create a PR on GitHub with:
   - Clear description of changes
   - Reference to related issues
   - Testing performed
   - Screenshots (if applicable)

## Development Guidelines

### Ansible Playbooks

- Use descriptive task names
- Add debug messages for important steps
- Handle errors gracefully with `ignore_errors` and conditionals
- Document required variables
- Test on clean Ubuntu installation

### Kubernetes Manifests

- Use proper API versions
- Pin versions explicitly
- Include resource limits/requests where appropriate
- Use namespaces for isolation
- Follow Flux best practices

### Flux Resources

- Use consistent naming
- Set appropriate intervals (10m default)
- Enable health checks where possible
- Document chart values changes
- Test reconciliation

### Makefile

- Keep targets simple and focused
- Add help text for all targets
- Check prerequisites before running
- Provide clear error messages

### Documentation

- Keep README up to date
- Update VERSIONS.md when changing versions
- Add examples for new features
- Use clear, concise language
- Include troubleshooting steps

## Project Structure

```
superkube/
├── ansible/playbooks/       # Automation scripts
├── kind/                    # Cluster configuration
├── clusters/dev/           # Flux configuration
├── gitops/                 # Application manifests
│   ├── sources/           # HelmRepository definitions
│   └── releases/          # HelmRelease definitions
├── Makefile               # User commands
├── README.md             # Main documentation
├── VERSIONS.md           # Version tracking
├── TESTING.md            # Test documentation
└── CONTRIBUTING.md       # This file
```

## Testing Requirements

All contributions must:

1. **Pass syntax validation:**
   ```bash
   kubectl kustomize gitops/
   ansible-playbook --syntax-check ansible/playbooks/*.yml
   ```

2. **Successfully bootstrap:**
   ```bash
   make up  # Must complete without errors
   ```

3. **Pass status checks:**
   ```bash
   make status  # All components Running/Ready
   ```

4. **Clean up properly:**
   ```bash
   make down  # Must remove all resources
   ```

## Adding New Components

To add a new application to the GitOps setup:

1. **Create HelmRepository** (if new chart source):
   ```yaml
   # gitops/sources/myapp.yaml
   apiVersion: source.toolkit.fluxcd.io/v1beta2
   kind: HelmRepository
   metadata:
     name: myapp-repo
     namespace: flux-system
   spec:
     interval: 10m
     url: https://charts.example.com
   ```

2. **Create HelmRelease**:
   ```yaml
   # gitops/releases/myapp.yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: myapp
   ---
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: myapp
     namespace: flux-system
   spec:
     interval: 10m
     chart:
       spec:
         chart: myapp
         version: 1.0.0  # Pin version!
         sourceRef:
           kind: HelmRepository
           name: myapp-repo
           namespace: flux-system
     targetNamespace: myapp
     values:
       # Chart values here
   ```

3. **Update kustomization.yaml**:
   ```yaml
   # gitops/kustomization.yaml
   resources:
     - sources/myapp.yaml
     - releases/myapp.yaml
   ```

4. **Update documentation**:
   - Add to README.md
   - Add to VERSIONS.md
   - Update Makefile status target if needed

5. **Test the addition**:
   ```bash
   kubectl kustomize gitops/  # Validate
   make up  # Test bootstrap
   ```

## Version Updates

When updating component versions:

1. **Update the version in gitops/releases/**:
   ```yaml
   spec:
     chart:
       spec:
         version: NEW.VERSION.HERE
   ```

2. **Update VERSIONS.md**:
   - Add to version history
   - Update compatibility matrix
   - Note any breaking changes

3. **Test the upgrade**:
   ```bash
   make up  # Start cluster
   # Push changes
   flux reconcile kustomization superkube-apps --with-source
   make status  # Verify
   ```

4. **Document changes**:
   - Update README if behavior changes
   - Add upgrade notes to VERSIONS.md

## Review Process

Pull requests will be reviewed for:

1. **Functionality**: Does it work as intended?
2. **Quality**: Is the code clean and maintainable?
3. **Testing**: Has it been adequately tested?
4. **Documentation**: Are docs updated?
5. **Style**: Does it follow project conventions?

## Getting Help

- Open an issue for questions
- Check existing documentation
- Review closed PRs for examples

## Recognition

Contributors will be recognized in:
- GitHub contributor list
- Release notes (for significant contributions)

Thank you for contributing to Superkube!
