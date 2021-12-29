# Traefik Installation
```shell
kubectl create ns traefik-v2

helm install --namespace=traefik-v2 \
    --set="additionalArguments={--log.level=DEBUG}" \
    traefik traefik/traefik
```

OR

```shell
helm upgrade --install traefik traefik/traefik --create-namespace -n traefik \
--set "ports.websecure.tls.enabled=true" \
--set "providers.kubernetesIngress.publishedService.enabled=true"
```

```shell
kubectl port-forward $(kubectl get pods --namespace traefik-v2 --selector "app.kubernetes.io/name=traefik" --output=name)  --namespace traefik-v2 9000:9000
```
