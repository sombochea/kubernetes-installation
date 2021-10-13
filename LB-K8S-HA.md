# Setup and Configuration k8s multiple master (HA)

- Keepalived
- HAProxy
- Kubernetes

### Nodes
- 2 servers for HA/Keepalived
- 3 servers for k8s master
- 5 servers for k8s worker

### Keepalived

- Install and start service

```shell
sudo apt-get install haproxy keepalived psmisc -y
sudo systemctl enable keepalived
sudo systemctl start keepalived
```

- Configuration for master nodes
- ha-master-1 `/etc/keepalived/keepalived.conf`

```config
global_defs {
   notification_email {
     sysadmin@cubetiqhost.net
     support@cubetiqhost.net
   }
   notification_email_from ha-master-1@cubetiqhost.net
   smtp_server localhost
   smtp_connect_timeout 30
}

vrrp_instance VI_1 {
    state MASTER
    interface ens18
    virtual_router_id 101
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.0.10
    }
}
```

- ha-master-2 (BACKUP) `/etc/keepalived/keepalived.conf`

```config
global_defs {
   notification_email {
     sysadmin@cubetiqhost.net
     support@cubetiqhost.net
   }
   notification_email_from ha-master-2@cubetiqhost.net
   smtp_server localhost
   smtp_connect_timeout 30
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens18
    virtual_router_id 101
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.0.10
    }
}
```

- Restart all nodes for keepalived service
```shell
sudo systemctl restart keepalived
```

- Edit HAProxy config (for all ha nodes)
```shell
sudo nano /etc/haproxy/haproxy.cfg
```

```text
frontend kubernetes
    bind 192.168.0.10:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-1 192.168.0.11:6443 check fall 3 rise 2
    server k8s-master-2 192.168.0.12:6443 check fall 3 rise 2
    server k8s-master-3 192.168.0.13:6443 check fall 3 rise 2

listen stats
    bind 192.168.0.10:8080 name hastats
    mode http
    stats enable
    stats uri /
    stats realm HAProxy\ Statistics
    stats auth admin:haproxy

```

- Enable HAProxy service
```shell
sudo systemctl enable --now haproxy
```

- Allow for No Local Bind IP Address (Ignore error in HAProxy)
```shell
echo "net.ipv4.ip_nonlocal_bind=1" | sudo tee /etc/sysctl.d/ip_nonlocal_bind.conf
sudo sysctl --system
```

- Restart HAProxy for configuration
```shell
sudo systemctl restart haproxy.service
```

- Use SSH Authentication (Copy Pub for nodes)
```shell
for i in $(seq 1 3); do \
ssh-copy-id -f -i $HOME/.ssh/id_rsa.pub 192.168.0.1${i};\
done;
```

#### Initialize cluster with kubeadm
- Setup k8s-master-1
```shell
sudo kubeadm init \
  --pod-network-cidr "10.16.1.0/8" \
  --service-dns-domain "apps-lb.cubetiqhost.net" \
  --control-plane-endpoint "k8s-lb.cubetiqhost.net:6443" \
  --upload-certs
```

- Cluster network with calico
```shell
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

```

- Join control-plane
```shell
sudo kubeadm join k8s-lb.cubetiqhost.net:6443 --token $TOKEN --discovery-token-ca-cert-hash $HASH b20a5a71d --control-plane --certificate-key $CERT_KEY
```

- Join worker
```shell
sudo kubeadm join k8s-lb.cubetiqhost.net:6443 --token $TOKEN --discovery-token-ca-cert-hash $HASH
```