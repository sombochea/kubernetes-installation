# Create RBAC for specific namespace

- Apply RBAC for specific namespace

```shell
k apply -f access.yaml
```

- Get Details of RBAC

```shell
k describe sa developer -n developer-dev
```

- Get Token from RBAC

```shell
k get secret developer-token-l4r67 -n developer-dev -o "jsonpath={.data.token}" | base64 -d
```

- Get Certificate from RBAC

```shell
k get secret developer-token-l4r67 -n developer-dev -o "jsonpath={.data['ca\.crt']}"
```

- Create kube config file

```yaml
apiVersion: v1
kind: Config
preferences: {}
 cluster:
      certificate-authority-data: PLACE CERTIFICATE HERE
      server: https://YOUR_KUBERNETES_API_ENDPOINT
    name: developer-cluster

users:
  - name: developer
    user:
      as-user-extra: {}
      client-key-data: PLACE CERTIFICATE HERE
      token: PLACE USER TOKEN HERE

contexts:
  - context:
      cluster: kubernetes
      namespace: developer-dev
      user: developer
    name: developer-dev

current-context: developer-dev
clusters:
  - cluster:
      certificate-authority-data: PLACE CERTIFICATE HERE
      server: https://YOUR_KUBERNETES_API_ENDPOINT
    name: developer-cluster

users:
  - name: developer
    user:
      as-user-extra: {}
      client-key-data: PLACE CERTIFICATE HERE
      token: PLACE USER TOKEN HERE

contexts:
  - context:
      cluster: kubernetes
      namespace: developer-dev
      user: developer
    name: developer-dev

current-context: developer-dev
```
