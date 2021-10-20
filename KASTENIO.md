# Install Kasten (K10) with Kind

### Prerequisites

- Install Kubernetes with kind

```shell
kind create cluster --name k10-demo --image kindest/node:v1.21.1 --wait 600s
```

```shell
# Install a recent version of the CSI snapshotter
SNAPSHOTTER_VERSION=v2.1.1

- Install the VolumeSnapshot CRDS and the Snapshot Controller
#  Create Snapshot Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create Snapshot Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/${SNAPSHOTTER_VERSION}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
```

- Install the CSI Hostpath Driver

```shell
git clone https://github.com/kubernetes-csi/csi-driver-host-path.git
cd csi-driver-host-path
./deploy/kubernetes-1.21/deploy.sh
```

- After the install is complete, add the CSI Hostpath Driver StorageClass and make it the default

```shell
kubectl apply -f ./examples/csi-storageclass.yaml
kubectl patch storageclass standard \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass csi-hostpath-sc \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Installing K10

```shell
helm repo add kasten https://charts.kasten.io/
kubectl create namespace kasten-io
helm install k10 kasten/k10 --namespace=kasten-io

# Annotate the CSI Hostpath VolumeSnapshotClass for use with K10 (optional)
kubectl annotate volumesnapshotclass csi-hostpath-snapclass \
    k10.kasten.io/is-snapshot-class=true
```

```shell
kubectl --namespace kasten-io port-forward service/gateway 8080:8000
```
