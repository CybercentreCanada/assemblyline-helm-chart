Minimal Appliance
============

This is a minimal appliance of the Assemblyline platform suited for 
smaller scale deployments such as on Minikube and MicroK8S.

Pre-Installation
------------

Follow the instructions as instructed in the [main chart directory](../assemblyline).

In addition, be sure to provide storageClasses for the following:
- datastore.volumeClaimTemplate.storageClassName
- log-storage.volumeClaimTemplate.storageClassName
- filestore.persistence.StorageClass

Failure to do so can lead to problems during a ```helm upgrade```.

MicroK8S Installation:
----------
1. Install addons:  ```microk8s enable dns ha-cluster ingress storage```
2. Install helm:    
```
snap install helm --classic
mkdir /var/snap/microk8s/current/bin
ln -s /snap/bin/helm /var/snap/microk8s/current/bin/helm
```

Minikube Installation:
----------
**Requires Docker driver to be installed.**

1. Startup minikube:  
```
minikube start 
--cpus <cpu_limit> \
--memory <memory_limit> \
--disk-size <disk_limit> \
--driver=docker
```

2. Enable ingress: ```minikube addons enable ingress```

3. Create a DNS entry in /etc/hosts that will resolve to ```$(minikube ip)```. 
Set this host under ```configuration.ui.fqdn``` in values.yaml


Helm install:
------------
After either above method is prepared:
```
helm install <name> assemblyline-helm-chart\assemblyline \
-f assemblyline-helm-chart\minimal_appliance\values.yaml \
-n <namespace>
```
