# Installation Guide for Kubernetes Cluster

#### Quick install for kubernetes cluster for worker node
```shell
curl -s -L https://raw.githubusercontent.com/sombochea/kubernetes-installation/main/kube-cluster-worker-install.sh?v=121020215 | bash
```

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

# Setup network
```shell
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
```

# Install kubernetes tools
### 1. Install CNI plugins (required for most pod network)
```shell
CNI_VERSION="v0.8.2"
ARCH="amd64"
sudo mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz
```

```shell
DOWNLOAD_DIR=/usr/local/bin
sudo mkdir -p $DOWNLOAD_DIR
```

### 2. Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI))
```shell
CRICTL_VERSION="v1.17.0"
ARCH="amd64"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
```

### 3. Install kubeadm, kubelet and add a kubelet systemd service
```shell
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}
sudo chmod +x {kubeadm,kubelet}

RELEASE_VERSION="v0.4.0"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl enable --now kubelet
```

### 4. Verify installation for kubernetes tools
```shell
kubeadm version
```

### 5. Disable swap and install docker.io
```shell
sudo swapoff -a
wget https://sh.osa.cubetiqs.com/docker-setup.sh
bash docker-setup.sh
sudo systemctl start docker
sudo systemctl enable docker

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

#### Install some required tools
```shell
sudo apt-get -y install socat conntrack
```

### 6. Configure containerd
```shell
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots. (If using crio)
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

```shell
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd
```

**If using crio**
- Update config
```shell
sudo nano /etc/containerd/config.toml
```
- Change SystemdCgroup from **false** to **true**
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```
- Restart containerd service
```shell
sudo systemctl restart containerd
```

### 7. Cluster on Master node
```shell
sudo kubeadm init --pod-network-cidr 10.16.1.0/8
```

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

##### OR Join Cluster
```shell
sudo kubeadm join ip-api-server:6443 --token $TOKEN --discovery-token-ca-cert-hash $DISCOVERY_HASH
```

#### Cluster Netowrk with Flannel
```shell
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
```

#### Cluster Network with Calico
```shell
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

#### Kubernetes Dashboard
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
```
- Proxy for kubernetes dashboard
```shell
kubectl proxy --namespace kubernetes-dashboard service/kubernetes-dashboard
```

- Access the proxy
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

- Get Token from service account "admin-user"
```shell
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

#### Deploy Storage Class with External NFS server
- Install nfs client for all nodes
```shell
sudo apt install nfs-common -y
```

- Install NFS External Provider
```shell
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
```

```shell
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=nfs-server-ip \
    --set nfs.path=/exported-path
```

#### Create Service Account for Kubernetes Dashboard Token
- Create file: `dashboard-adminuser.yml`
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
```
```shell
 kubectl apply -f dashboard-adminuser.yml
 ```
 
- Create file: `admin-role-binding.yml`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```
```shell
 kubectl apply -f admin-role-binding.yml
 ```
- Get Token
```shell
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

#### Get Kubernetes PKI Hash for Kubeadm
```shell
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

#### Fix Helm Kube Config
```text
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: ~/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: ~/.kube/config
```
```shell
chmod o-r ~/.kube/config
chmod g-r ~/.kube/config
```

#### Install kubectl and helm for Windows
- https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
- https://helm.sh/docs/intro/install/

#### References
- https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
