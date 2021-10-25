# Install Verdaccio

- Installing

```shell
helm repo add verdaccio https://charts.verdaccio.org
helm install npm verdaccio/verdaccio
```

- Create pvc from existing nfs-pc

```shell
kubectl create -f pvc.yaml
```
