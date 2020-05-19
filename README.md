# Otus Kubernetes course

## HW-3 K8s security

### How to use

Clone repo. Start k8s. Run `cd kubernetes-security`. Run commands bellow.

### Get status

#### Cluster info 

```
└─$> kubectl cluster-info dump | grep authorization-mode
                            "--authorization-mode=Node,RBAC",
```
or
```
└─$> kubectl -n kube-system describe pod kube-apiserver-minikube 
Name:                 kube-apiserver-minikube
Namespace:            kube-system
Priority:             2000000000
...
```

#### Api resourses https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.17/

```
└─$>  kubectl api-resources
NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND
bindings                                                                      true         Binding
componentstatuses                 cs                                          false        ComponentStatus
configmaps                        cm                                          true         ConfigMap
endpoints                         ep                                          true         Endpoints
...
```

### Palying with SA CR CRB

For example `cd task01`

#### Create ServiceAccount

```
└─$> kubectl apply -f ./01-sa-bob.yaml 
serviceaccount/bob created

└─$> kubectl apply -f ./03-sa-dave.yaml 
serviceaccount/dave created

└─$> kubectl get sa
NAME      SECRETS   AGE
bob       1         4m57s
dave      1         5s
default   1         15d
```
cd 
#### Create ClusterRoleBinding

```
└─$> kubectl apply -f ./02-crb-bob.yaml 
clusterrolebinding.rbac.authorization.k8s.io/bob-cluster-admin created

└─$> kubectl get clusterrolebinding
NAME                                                   ROLE                                                                               AGE
bob-cluster-admin                                      ClusterRole/cluster-admin                                                          2m20s
cluster-admin                                          ClusterRole/cluster-admin                                                          15d
```

### Exmples

You can find some examples in dir `examples`.



## HW-2 Kubernetes controllers

### How to use

Clone repo. Cd in dir `kubernetes-controllers`. Run commands bellow.

### Kind 

##### Install 

https://kind.sigs.k8s.io/docs/user/quick-start/

##### Start 
```
└─$> kind create cluster --config kind-config.yaml
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.18.2) 🖼 
 ✓ Preparing nodes 📦 📦 📦 📦 📦 📦  
 ✓ Configuring the external load balancer ⚖️ 
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining more control-plane nodes 🎮 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Thanks for using kind! 😊
```

##### Status
```
└─$> kubectl get nodes
NAME                  STATUS   ROLES    AGE     VERSION
kind-control-plane    Ready    master   3m41s   v1.18.2
kind-control-plane2   Ready    master   3m11s   v1.18.2
kind-control-plane3   Ready    master   2m31s   v1.18.2
kind-worker           Ready    <none>   2m13s   v1.18.2
kind-worker2          Ready    <none>   2m13s   v1.18.2
kind-worker3          Ready    <none>   2m13s   v1.18.2
```

### Controllers

#### ReplicaSet

https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/

##### Create
```
─$> kubectl apply -f ./frontend-replicaset.yaml
replicaset.apps/frontend created

└─$> kubectl scale replicaset frontend --replicas=3
replicaset.apps/frontend scaled

─$> kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-54ntp   1/1     Running   0          63s
frontend-9mdpz   1/1     Running   0          63s
frontend-mxzc6   1/1     Running   0          63s

└─$> kubectl get rs frontend
NAME       DESIRED   CURRENT   READY   AGE
frontend   3         3         3       2m16s
```

##### Try delete and get rise again
```
└─$> kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
...

└─$> kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-727g8   1/1     Running   0          66s
frontend-8wt4p   1/1     Running   0          66s
frontend-h9hbv   1/1     Running   0          66s
```

##### Change image version

We edit in `frontend-replicaset.yaml` docker image version and aplly it but nothing happend.

Check current versions:
```
└─$> kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-frontend:v0.0.2
 
└─$> kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}'
revard/otus-k8s-frontend:latest
```

Now we delete all pods and recreate.
```
└─$> kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
...
```

Get new image version. 
```
└─$> kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-frontend:v0.0.2
```

!!! It happend because ReplicaSet doesn`t check manifest!!! 

#### Deployment

##### Aplly
```
└─$> kubectl apply -f ./paymentservice-deployment.yaml
deployment.apps/paymentservice created

└─$> kubectl get ds
No resources found in default namespace.

└─$> kubectl get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
paymentservice   1/3     3            1           16s

└─$> kubectl get rs
NAME                       DESIRED   CURRENT   READY   AGE
paymentservice-bdf74f647   3         3         1       22s

└─$> kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
paymentservice-bdf74f647-4svkd   1/1     Running   0          90s
paymentservice-bdf74f647-htvll   1/1     Running   0          90s
paymentservice-bdf74f647-qmc64   1/1     Running   0          90s
```

##### Rolling Update (default). Let`s change version in deployment manifest and apply. 
```
alf@alf-pad:~/revard_platform/kubernetes-controllers (kubernetes-controllers) 
└─$> kubectl apply -f paymentservice-deployment.yaml 

└─$> kubectl get replicaset 
NAME                        DESIRED   CURRENT   READY   AGE
paymentservice-7d745d469d   3         3         3       2m6s
paymentservice-bdf74f647    0         0         0       4m33s

└─$> kubectl get replicaset paymentservice-7d745d469d -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-paymentservice:v0.0.2 
└─$> kubectl get replicaset paymentservice-bdf74f647 -o=jsonpath='{.spec.template.spec.containers[0].image}'
revard/otus-k8s-paymentservice:v0.0.1

```

##### History
```
└─$> kubectl rollout history deployment paymentservice
deployment.apps/paymentservice 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

##### Rollback
```
└─$> kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -l app=paymentservice -w
...

└─$> kubectl get replicaset 
NAME                        DESIRED   CURRENT   READY   AGE
paymentservice-7d745d469d   0         0         0       15m
paymentservice-bdf74f647    3         3         3       18m
```

##### Deployment strategy

We can use `Max Surge` and `Max Unavailable` parameters. 

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy

Blue-Green example in `paymentservice-deployment-bg.yaml`

Reverse Rolling Update in `paymentservice-deployment-reverse.yaml`

#### Probes

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

##### Check status
```
└─$> kubectl describe pod | grep Readiness
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:8080/_healthz delay=10s timeout=1s period=10s #success=1 #failure=3
```

##### Wrong probe example
```
─$> kubectl get pod 
NAME                        READY   STATUS    RESTARTS   AGE
frontend-7cd948bf65-cb6h7   1/1     Running   0          68m
frontend-7cd948bf65-t5w4n   1/1     Running   0          68m
frontend-7cd948bf65-vnsc9   1/1     Running   0          68m
frontend-7f454bbbf8-crpvw   0/1     Running   0          18s

└─$> kubectl describe pod  frontend-7f454bbbf8-crpvw
...
Events:
  Type     Reason     Age               From                  Message
  ----     ------     ----              ----                  -------
...
  Warning  Unhealthy  4s (x2 over 14s)  kubelet, kind-worker  Readiness probe failed: HTTP probe failed with statuscode: 404  
```

##### Deployment status
```
└─$> kubectl rollout status deployment/frontend
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "frontend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "frontend" rollout to finish: 1 old replicas are pending termination...
deployment "frontend" successfully rolled out
```

##### Probe status examples fot GitLab CI/CD
```
deploy_job:
stage: deploy
script:
- kubectl apply -f frontend-deployment.yaml
- kubectl rollout status deployment/frontend --timeout=60s
```
```
rollback_deploy_job:
stage: rollback
script:
- kubectl rollout undo deployment/frontend
when: on_failure
```

#### DaemonSet

We try run `node-exporter-daemonset`

```
└─$> kubectl apply -f node-exporter-daemonset.yaml 
daemonset.apps/node-exporter created

└─$> kubectl get ds
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
node-exporter   6         6         0       6            0           kubernetes.io/os=linux   6s
 
└─$> kubectl get pods 
NAME                        READY   STATUS    RESTARTS   AGE
frontend-58d98549cb-4zclg   1/1     Running   0          10m
frontend-58d98549cb-srr46   1/1     Running   0          11m
frontend-58d98549cb-vsgss   1/1     Running   0          10m
node-exporter-d2xkf         2/2     Running   0          2m36s
node-exporter-k8cjd         2/2     Running   0          2m36s
node-exporter-pwjfb         2/2     Running   0          2m36s
node-exporter-q84vz         2/2     Running   0          2m36s
node-exporter-r46xc         2/2     Running   0          2m36s
node-exporter-r7gth         2/2     Running   0          2m36s
```

##### Test. Forward port and get all ok.
```
└─$> kubectl port-forward node-exporter-d2xkf 9100:9100
Forwarding from 127.0.0.1:9100 -> 9100
Forwarding from [::1]:9100 -> 9100
Handling connection for 9100

└─$> curl localhost:9100/metrics
# HELP go_gc_duration_seconds A summary of the GC invocation durations.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
```

As we can see DaemonSet run on all nodes:
```
└─$> kubectl describe nodes  | egrep "Name:|node-exporte"
Name:               kind-control-plane
  default                     node-exporter-z47qv                           112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-control-plane2
  default                     node-exporter-v2qqb                            112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-control-plane3
  default                     node-exporter-rxw47                            112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-worker
  default                     node-exporter-fh25z          112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-worker2
  default                     node-exporter-4m62w          112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
Name:               kind-worker3
  default                     node-exporter-5rcct          112m (1%)     270m (3%)   200Mi (1%)       220Mi (1%)     3m3s
```

If for some reason daemonset won`t run on master nodes you can setup toleration:
```
...
kind: DaemonSet
spec:
  ...
  template:
   ...
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
```


## HW-1 Kubernetes Intro

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

Try find out what is wrong with frontend pod.

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

#### Links

https://github.com/GoogleCloudPlatform/microservices-demo.git