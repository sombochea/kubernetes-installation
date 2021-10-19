# Install Operator OLM

### Install Operator SDK (macOS/Linux)
```shell
brew install operator-sdk
```

### Install Operator SDK on Linux
```shell
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.13.1
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -
chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk
```

### Install Operator OLM
```shell
operator-sdk olm install
```

### Check Operator Status
```shell
operator-sdk olm status
```

### Fix OLM Installation by manually
```shell
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.15.1/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.15.1/olm.yaml
```

### Reference
- https://olm.operatorframework.io/docs/getting-started