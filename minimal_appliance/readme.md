# Minimal Appliance

This is a minimal appliance of the Assemblyline platform suited for 
smaller scale deployments such as on Minikube and MicroK8S.

## Setup requirements

### Install pre-requisites:

1. Install docker: 
```
snap install docker
```
2. Install microk8s: 
```
snap install microk8s --classic
```
3. Install microk8s addons:  
```
sudo microk8s enable dns ha-cluster ingress storage
```
4. Install helm:    
```
snap install helm --classic
```
5. Install git: 
```
sudo apt install git
```

### (Optional) Add more nodes!!!
**Note: This can be done before or after the system is live.**

From the master node, run:
```
sudo microk8s add-node
```

This will generate a command with a token to be executed on a standby node.

On your standby node, ensure the microk8s ```ha-cluster``` addon is enabled before
running the command from the master to join the cluster.

To verify the nodes are connected, run (on any node): 
```
sudo microk8s kubectl get nodes
```

Repeat this process for any additional standby nodes that's to be added.

For more details, see: [Clustering with MicroK8s](https://microk8s.io/docs/clustering)

## Get the Assemblyline chart to your computer

### Get the Assemblyline helm charts

```
mkdir ~/git && cd ~/git
git clone https://github.com/CybercentreCanada/assemblyline-helm-chart.git
```

### Setup the charts and secrets

The values.yml file is already pre-configured for use with microk8s on a basic one node appliance, 
you should still have a look at the base helm instructions in the [main chart directory](../assemblyline).

The secret.yml is preconfigured with default password, you should definitely change them.

## Deploy Assemblyline via Helm:

### Create a namespace for your Assemblyline install

For the purpose of this documentation we will use ```al``` as the namespace.

```
sudo microk8s kubectl create namespace al
```

### Deploy de secret to the namespace

```
sudo microk8s kubectl apply -f ~/git/assemblyline-helm-chart/minimal_appliance/secrets.yaml --namespace=al
```

### Finally, let's deploy Assemblyline's chart:

For the purpose of this documentation we will use ```assemblyline``` as the deployment name.

```
helm install assemblyline ~/git/assemblyline-helm-chart/assemblyline \
-f ~/git/assemblyline-helm-chart/minimal_appliance/values.yaml \
-n al
```

## Alternative Installations:

### Minikube setup
Note: Minikube doesn't support multi-node

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

#### Setup the chart

Since the provided chart is setup for microk8s, you will have to change the storage classes in the values.yml to work with minikube
