# Installation Guide for Kubernetes Cluster

### 1. Download kubectl
```shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
### 2. Validate kubectl
```shell
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
```

### 3. Install kubectl
```shell
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

##### If none-root access (for local user)
```shell
chmod +x kubectl
mkdir -p ~/.local/bin/kubectl
mv ./kubectl ~/.local/bin/kubectl
# and then add ~/.local/bin/kubectl to $PATH
```

### 4. Verify kubectl installed
```shell
kubectl version --client
```

# Install Helm 3
```shell
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
