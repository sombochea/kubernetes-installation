# Install NGINX Ingress Controller

- Add Ingress Repository

```shell
helm repo add cubetiq-ingress-nginx https://charts.ctdn.net/ingress-nginx
helm repo update
```

- Install Ingress Controller

```shell
helm install nginx-ingress cubetiq-ingress-nginx/ingress-nginx --set controller.publishService.enabled=true
```

NAME: nginx-ingress
LAST DEPLOYED: Tue Oct 12 15:03:45 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace default get services -o wide -w nginx-ingress-ingress-nginx-controller'

An example Ingress that makes use of the controller:

```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls
```
If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
  ```