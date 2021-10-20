# Quick Kubernetes Local on KIND

### Install Kind and create cluster (local)

```shell
GO111MODULE="on" go get sigs.k8s.io/kind@v0.11.1 && kind create cluster
```

### Install Kubeapps

- Add Bitnami Repo

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
kubectl create namespace kubeapps
helm install kubeapps --namespace kubeapps bitnami/kubeapps
```

- Install Kubeapps

```shell
kubectl create --namespace default serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator
```

- Get Token

```shell
kubectl get secret $(kubectl get serviceaccount kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo
```

### Reference

- https://kind.sigs.k8s.io/
- https://kubeapps.com/docs/getting-started/
