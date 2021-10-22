# Docker Private Registry for Kubernetes

- Create secret
```shell
kubectl create secret generic regcred \
--from-file=.dockerconfigjson=$HOME/.docker/config.json \
--type=kubernetes.io/dockerconfigjson
```

OR

```shell
kubectl create secret docker-registry regcred --docker-server=registry.kh.cubetiqs.com --docker-username=sombochea --docker-password=<your-pword> --docker-email=sombochea@cubetiqs.com
```

- View your secret
```shell
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

- Create sample pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
  - name: regcred
```