# Otus Kubernete course
revard Platform repository

## HW-2 Kubernetes Intro

### Install

* kubectl 

https://kubernetes.io/docs/tasks/tools/install-kubectl/

* minicube

https://kubernetes.io/docs/tasks/tools/install-minikube/

* kind

https://kind.sigs.k8s.io/docs/user/quick-start/

* Web UI (Dashboard)

https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

* Kubernetes CLI

https://k9scli.io/


### Minikube

#### Start

```
alf@alf-pad:~/revard_platform (master) 
└─$>  minikube start
😄  minikube v1.9.2 on Ubuntu 20.04
✨  Automatically selected the docker driver
👍  Starting control plane node m01 in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.18.0 preload ...
    > preloaded-images-k8s-v2-v1.18.0-docker-overlay2-amd64.tar.lz4: 542.91 MiB
🔥  Creating Kubernetes in docker container with (CPUs=2) (8 available), Memory=3900MB (15909MB available) ...
🐳  Preparing Kubernetes v1.18.0 on Docker 19.03.2 ...
    ▪ kubeadm.pod-network-cidr=10.244.0.0/16
🌟  Enabling addons: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube"
```

#### Check config

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl cluster-info
Kubernetes master is running at https://172.17.0.2:8443
KubeDNS is running at https://172.17.0.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


alf@alf-pad:~/revard_platform (master) 
└─$> kubectl config view
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/alf/.minikube/ca.crt
    server: https://172.17.0.2:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /home/alf/.minikube/profiles/minikube/client.crt
    client-key: /home/alf/.minikube/profiles/minikube/client.key
```

#### Playing with k8s

* Connect to k8s and try delete containers. As we see they rise again.

```
alf@alf-pad:~/revard_platform (master) 
└─$> minikube ssh

docker@minikube:~$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
57d75b38e437        67da37a9a360           "/coredns -conf /etc…"   2 hours ago         Up 2 hours                              k8s_coredns_coredns-66bff467f8-dwcwl_kube-system_7afa9fa7-a1b4-4ceb-baa1-855b25be6c8e_0
358c69b2d37d        67da37a9a360           "/coredns -conf /etc…"   2 hours ago         Up 2 hours                              k8s_coredns_coredns-66bff467f8-sw6zt_kube-system_e486de76-96c3-41e6-8efb-0bc6ae98341f_0
...

docker@minikube:~$ docker rm -f $(docker ps -a -q)
57d75b38e437
358c69b2d37d
...

docker@minikube:~$ docker ps
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS               NAMES
774796c60f8e        67da37a9a360           "/coredns -conf /etc…"   5 seconds ago       Up 3 seconds                            k8s_coredns_coredns-66bff467f8-dwcwl_kube-system_7afa9fa7-a1b4-4ceb-baa1-855b25be6c8e_0
5d249edbe72b        67da37a9a360           "/coredns -conf /etc…"   5 seconds ago       Up 3 seconds                            k8s_coredns_coredns-66bff467f8-sw6zt_kube-system_e486de76-96c3-41e6-8efb-0bc6ae98341f_0
...
```

* Status by kubernetes NS

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get pods -n kube-system

NAME                               READY   STATUS    RESTARTS   AGE
coredns-66bff467f8-dwcwl           1/1     Running   0          137m
coredns-66bff467f8-sw6zt           1/1     Running   0          137m
etcd-minikube                      1/1     Running   0          137m
kindnet-bnbvp                      1/1     Running   0          137m
kube-apiserver-minikube            1/1     Running   0          137m
kube-controller-manager-minikube   1/1     Running   0          137m
kube-proxy-jq5jt                   1/1     Running   0          137m
kube-scheduler-minikube            1/1     Running   0          137m
storage-provisioner                1/1     Running   1          137m

```
* Delete again and get all ok.

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl delete pod --all -n kube-system
pod "coredns-66bff467f8-dwcwl" deleted
pod "coredns-66bff467f8-sw6zt" deleted
pod "etcd-minikube" deleted
pod "kindnet-bnbvp" deleted
pod "kube-apiserver-minikube" deleted
pod "kube-controller-manager-minikube" deleted
pod "kube-proxy-jq5jt" deleted
pod "kube-scheduler-minikube" deleted
pod "storage-provisioner" deleted

alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get componentstatuses (cs)
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}  
```

### Pods in NS kube-system are recreating due:

1. Kubernetes static pods in manifest dir controled directly by kublet.

```
docker@minikube:~$ ll /etc/kubernetes/manifests/                   
...
-rw------- 1 root root 1895 May  3 15:48 etcd.yaml
-rw------- 1 root root 3429 May  3 15:48 kube-apiserver.yaml
-rw------- 1 root root 3105 May  3 15:48 kube-controller-manager.yaml
-rw------- 1 root root 1120 May  3 15:48 kube-scheduler.yaml
```

2. Core-dns is recreated by Deployment.

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get deployment --namespace=kube-system -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                     SELECTOR
coredns   2/2     2            2           17h   coredns      k8s.gcr.io/coredns:1.6.7   k8s-app=kube-dns
```

3. Kube-proxy recreated by DaemonSet.

```
alf@alf-pad:~/revard_platform (master) 
└─$> kubectl get ds --namespace=kube-system -o wide
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE   CONTAINERS    IMAGES                          SELECTOR
kindnet      1         1         1       1            1           <none>                   17h   kindnet-cni   kindest/kindnetd:0.5.3          app=kindnet
kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   17h   kube-proxy    k8s.gcr.io/kube-proxy:v1.18.0   k8s-app=kube-proxy
```

### Playing with pods

#### Web app

* Create pod

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl apply -f web-pod.yaml
pod/web created

alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl get pods
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          10s
```

* Delete pod

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl delete pod web
pod "web" deleted
```

* Recreate pod

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl apply -f web-pod.yaml && kubectl get pods -w
pod/web created
NAME   READY   STATUS     RESTARTS   AGE
web    0/1     Init:0/1   0          0s
web    0/1     Init:0/1   0          2s
web    0/1     PodInitializing   0          3s
web    1/1     Running           0          6s
```

* Forward port

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
Forwarding from 0.0.0.0:8000 -> 8000
Handling connection for 8000
Handling connection for 8000
```

Alternative - https://kube-forwarder.pixelpoint.io/

#### Hipster frontend app

* Run

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl run frontend --image revard/otus-k8s-frontend --restart=Never
pod/frontend created

alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
frontend   0/1     Error     0          33s
web        1/1     Running   0          18h
```

* Generate manifest

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl run frontend --image revard/otus-k8s-frontend --restart=Never --dry-run=client -o yaml > frontend-pod.yaml
```

### Torubleshooting

Try find out what is rong with frontend pod.

Let`s see status:
```
alf@alf-pad:~/tmp/microservices-demo/src/frontend (master) 
└─$> kubectl describe pod frontend
Name:         frontend
Namespace:    default
Priority:     0
Node:         minikube/172.17.0.2
Start Time:   Tue, 05 May 2020 10:44:32 +0300
Labels:       run=frontend
Annotations:  <none>
Status:       Failed
IP:           172.18.0.3
IPs:
  IP:  172.18.0.3
Containers:
  frontend:
    Container ID:   docker://69788574e7c0cac911cdbd58a756c840ad40e62b960543448a291635dc09de56
    Image:          revard/otus-k8s-frontend
    Image ID:       docker-pullable://revard/otus-k8s-frontend@sha256:6fce3b26da2e5d089c57f326371866d034c8e1db527dfa3a385b10c1125a04c9
    Port:           <none>
    Host Port:      <none>
    State:          Terminated
      Reason:       Error
      Exit Code:    2
      Started:      Tue, 05 May 2020 10:44:38 +0300
      Finished:     Tue, 05 May 2020 10:44:38 +0300
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-gkg4c (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  default-token-gkg4c:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-gkg4c
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  6m30s  default-scheduler  Successfully assigned default/frontend to minikube
  Normal  Pulling    6m29s  kubelet, minikube  Pulling image "revard/otus-k8s-frontend"
  Normal  Pulled     6m24s  kubelet, minikube  Successfully pulled image "revard/otus-k8s-frontend"
  Normal  Created    6m24s  kubelet, minikube  Created container frontend
  Normal  Started    6m24s  kubelet, minikube  Started container frontend
```

Events look good. Take a look on container. Quick way is `kubectl logs frontend`

```
alf@alf-pad:~/revard_platform (master)
└─$> minikube ssh

docker@minikube:~$ docker logs $(docker ps -a | grep otus-k8s-frontend | awk '{print $1}')
{"message":"Tracing enabled.","severity":"info","timestamp":"2020-05-05T07:44:38.251381079Z"}
{"message":"Profiling enabled.","severity":"info","timestamp":"2020-05-05T07:44:38.251476052Z"}
{"message":"jaeger initialization disabled.","severity":"info","timestamp":"2020-05-05T07:44:38.25165138Z"}
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set

goroutine 1 [running]:
main.mustMapEnv(0xc0003b4000, 0xb0f14e, 0x1c)
	/go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:259 +0x10e
main.main()
	/go/src/github.com/GoogleCloudPlatform/microservices-demo/src/frontend/main.go:117 +0x4ff
```

So we have enviroment variable issue. Let`s fix this by adding ENV to manifest an restart pod.

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master)
└─$> kubectl delete pod frontend
pod "frontend" deleted

alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl apply -f frontend-pod-healthy.yaml && kubectl get pods -w
pod/frontend created
NAME       READY   STATUS              RESTARTS   AGE
frontend   0/1     ContainerCreating   0          0s
web        1/1     Running             0          19h
frontend   1/1     Running             0          4s
```

Now all is OK!

```
alf@alf-pad:~/revard_platform/kubernetes-intro (master) 
└─$> kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          77s
web        1/1     Running   0          19h
```