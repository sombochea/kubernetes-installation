# Setup and Configuration k8s multiple master (HA)

- Keepalived
- HAProxy
- Kubernetes

### Keepalived

- Install and start service

```shell
sudo apt-get install keepalived -y
sudo systemctl enable keepalived
sudo systemctl start keepalived
```

- Configuration for master nodes
- k8s-master-1 `/etc/keepalived/keepalived.conf`

```config
global_defs {
   notification_email {
     sysadmin@cubetiqhost.net
     support@cubetiqhost.net
   }
   notification_email_from k8s-master-1@cubetiqhost.net
   smtp_server localhost
   smtp_connect_timeout 30
}

vrrp_instance VI_1 {
    state MASTER
    interface ens18
    virtual_router_id 101
    priority 101
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

- k8s-master-2 (BACKUP) `/etc/keepalived/keepalived.conf`

```config
global_defs {
   notification_email {
     sysadmin@cubetiqhost.net
     support@cubetiqhost.net
   }
   notification_email_from k8s-master-2@cubetiqhost.net
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

- k8s-master-3 (BACKUP) `/etc/keepalived/keepalived.conf`

```config
global_defs {
   notification_email {
     sysadmin@cubetiqhost.net
     support@cubetiqhost.net
   }
   notification_email_from k8s-master-3@cubetiqhost.net
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