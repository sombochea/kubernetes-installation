#!/bin/bash -e

echo "Downloading kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

echo "Installing kubectl..."
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
chmod +x kubectl
mkdir -p ~/.local/bin/kubectl
mv ./kubectl ~/.local/bin/kubectl

echo "Verify kubectl client version"
kubectl version --client

echo "Downloading and install helm3..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Setup network k8s module..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

echo "Downloading and install CNI plguins..."
CNI_VERSION="v0.8.2"
ARCH="amd64"
sudo mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz" | sudo tar -C /opt/cni/bin -xz

echo "Downloading and install cri tools..."
CRICTL_VERSION="v1.17.0"
ARCH="amd64"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz

echo "Downloading and install kubeadm and kubelet..."
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}
sudo chmod +x {kubeadm,kubelet}

echo "Setting up kubelet service..."
RELEASE_VERSION="v0.4.0"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "Enabling kubelet service..."
sudo systemctl enable --now kubelet

echo "Verify kubeadm version..."
kubeadm version

echo "Downloading and setup docker, containerd and tools..."
sudo swapoff -a
wget https://sh.osa.cubetiqs.com/docker-setup.sh
bash docker-setup.sh
sudo systemctl start docker
sudo systemctl enable docker

echo "Enabling docker daemon for cgroup driver with systemd"
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

echo "Restart docker service..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Installing socat and conntrack for kubernetes cluster..."
sudo apt-get -y install socat conntrack

echo "Install nfs client tools..."
sudo apt install nfs-common -y

echo "Setting up containerd and configuration..."
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

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

echo "Create directory and config in $HOME/.kube"
mkdir -p $HOME/.kube
touch $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod o-r $HOME/.kube/config
chmod g-r $HOME/.kube/config

echo "Finished installation for kubectl, kubeadm and kubelet and some required tools, and now you do cluster :)!"
