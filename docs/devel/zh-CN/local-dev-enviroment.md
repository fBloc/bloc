# 本地开发/测试环境搭建指南

> 此文对象是开发者，讲解如何搭建本地开发环境
> 
> 这里的开发者指的是bloc下任何项目的开发者

本文推荐/介绍的是通过`mikikube`搭建本地开发环境。（不需要懂k8s知识，看完文章就可以了。如果您懂的话，相信你会有更便捷的部署方式👏）

**目录:**
* [安装minikube](#安装minikube)
* [部署后端所需服务](#部署后端所需服务)
    + 部署MongoDB服务
    + 部署RabbitMQ服务
    + 部署Minio服务
* [部署bloc-server](#部署bloc-server)
* [部署bloc-frontend](#部署bloc-frontend)
* [部署bloc-client-go](#部署bloc-client-go)
* [部署bloc-client-python](#部署bloc-client-python)

## 安装minikube
安装minikube的官方指导见[doc](https://minikube.sigs.k8s.io/docs/start/)

有几点说明下：
1. 要求你本机先安装并启动了docker，如果没有安装，请先安装
2. 要求安装机满足以下条件:
    1. 2 CPUs or more
    2. 2GB of free memory
    3. 20GB of free disk space
    4. Internet connection
3. **安装/启动过程特别简单**，下载minikube后通过命令`minikube start`启动一个由1个节点构成的**kubernetes集群**

## 部署后端所需服务
> 后端依赖的外部服务组件有三个：mongoDB、minio、rabbitMQ
> 
> 这三个目前为止是稳定需要的，无论你是想在本地开发bloc的任何部分，都是需要先部署好这三个依赖的

### 部署MongoDB服务
1. **创建以下yaml文件**，假设叫`bloc-mongo.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-read
  labels:
    name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  selector:
    role: mongo
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
spec:
  serviceName: "mongo"
  replicas: 1
  selector:
    matchLabels:
      role: mongo
      environment: test
  template:
    metadata:
      labels:
        role: mongo
        environment: test
    spec:
      containers:
        - name: mongo
          image: mongo:5.0.5
          args: ["--dbpath", "/data/db", "--port", "27017"]
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo
              mountPath: /data/db
  volumeClaimTemplates:
    - metadata:
        name: mongo
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi
```

2. 使用以下命令**启动服务**：
```shell
$ kubectl create -f bloc-mongo.yaml
```

3. 使用以下命令**检查服务是否启动完成**了：
```shell
$ kubectl get pods
NAME          READY   STATUS    RESTARTS      AGE
mongo-0       1/1     Running   0             30m
```
在其中看到`STATUS`值为`Running`就知道是启动成功了

4. 服务**有效性检验**：
上面我们已经部署完成了，接下来通过进入到容器连接服务来验证下部署是不是成功的。
```shell
# 查看pods的名字
$ kubectl get pods
NAME          READY   STATUS    RESTARTS      AGE
mongo-0       1/1     Running   0             33m
------------------------------------------------------------
# 通过pods的名字，进到对应的pod（可以理解为就是进入到对应的mongo container）
$ kubectl exec -it mongo-0 -- /bin/sh
# mongo  # 注意：这是在container中执行mongo命令连接server
MongoDB shell version v5.0.5
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("7f6be391-91f2-4794-b92f-a5d31e2f9fb7") }
MongoDB server version: 5.0.5
================
> show dbs;
admin   0.000GB
config  0.000GB
local   0.000GB
```
好啦，现在我们通过执行`show dbs`命令已经知道server是有效搭建好啦

### 部署RabbitMQ服务
1. **创建以下yaml文件**，假设叫`bloc-rabbit.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: rabbit
  labels:
    name: rabbit
spec:
  ports:
    - name: api
      protocol: TCP
      port: 5672
      targetPort: 5672
    - name: ui
      protocol: TCP
      port: 15672
      targetPort: 15672
  clusterIP: None
  selector:
    role: rabbit
---
apiVersion: v1
kind: Service
metadata:
  name: rabbit-read
  labels:
    name: rabbit
spec:
  ports:
    - name: api
      protocol: TCP
      port: 5672
      targetPort: 5672
    - name: ui
      protocol: TCP
      port: 15672
      targetPort: 15672
  selector:
    role: rabbit
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbit
spec:
  serviceName: "rabbit"
  replicas: 1
  selector:
    matchLabels:
      role: rabbit
      environment: test
  template:
    metadata:
      labels:
        role: rabbit
        environment: test
    spec:
      containers:
        - name: rabbit
          env:
            - name: RABBITMQ_DEFAULT_USER
              value: "blocRabbit"
            - name: RABBITMQ_DEFAULT_PASS
              value: "blocRabbitPasswd"
          image: rabbitmq:3.9.11-management
          ports:
            - name: amqp
              containerPort: 5672
              protocol: TCP
            - name: management
              containerPort: 15672
              protocol: TCP
  volumeClaimTemplates:
    - metadata:
        name: rabbit
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi
```

2. 使用以下命令**启动服务**：
```shell
$ kubectl create -f bloc-rabbit.yaml
```

3. 使用以下命令**检查服务是否启动完成**了：
```shell
$ kubectl get pods
NAME          READY   STATUS    RESTARTS      AGE
mongo-0       1/1     Running   0             3h44m
rabbit-0      1/1     Running   0             48m
```
在其中看到`rabbit-0`的`STATUS`值为`Running`就知道是启动成功了

4. 服务**有效性检验**：
上面我们已经部署完成了，接下来通过连接rabbit的management界面来验证下部署是不是成功的。
```shell
# 查看有哪些service（主要看下其中的rabbit-readservic是存在的）
$ kubectl get services
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
mongo         ClusterIP   None            <none>        27017/TCP            3h47m
mongo-read    ClusterIP   10.109.241.29   <none>        27017/TCP            3h47m
rabbit        ClusterIP   None            <none>        5672/TCP,15672/TCP   50m
rabbit-read   ClusterIP   10.98.131.195   <none>        5672/TCP,15672/TCP   50m
------------------------------------------------------------
# 通过minikube service命令提供访问rabbit-read service的
$ minikube service rabbit-read
|-----------|-------------|-------------|--------------|
| NAMESPACE |    NAME     | TARGET PORT |     URL      |
|-----------|-------------|-------------|--------------|
| default   | rabbit-read |             | No node port |
|-----------|-------------|-------------|--------------|
😿  service default/rabbit-read has no node port
🏃  Starting tunnel for service rabbit-read.
|-----------|-------------|-------------|------------------------|
| NAMESPACE |    NAME     | TARGET PORT |          URL           |
|-----------|-------------|-------------|------------------------|
| default   | rabbit-read |             | http://127.0.0.1:54755 |
|           |             |             | http://127.0.0.1:54756 |
|-----------|-------------|-------------|------------------------|
🎉  正通过默认浏览器打开服务 default/rabbit-read...
🎉  正通过默认浏览器打开服务 default/rabbit-read...
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```
好啦，现在到浏览器打开`http://127.0.0.1:54756`就能够通过yaml文件中的user/password登陆管理界面了！
![rabbitMQ management UI](/static/bloc_deploy_rabbit_management_example.png)

## 部署Minio服务
1. **创建以下yaml文件**，假设叫`bloc-minio.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: minio
  labels:
    name: minio
spec:
  ports:
    - name: api
      protocol: TCP
      port: 9000
      targetPort: 9000
    - name: console-ui
      protocol: TCP
      port: 9001
      targetPort: 9001
  clusterIP: None
  selector:
    role: minio
---
apiVersion: v1
kind: Service
metadata:
  name: minio-read
  labels:
    name: minio
spec:
  ports:
    - name: api
      protocol: TCP
      port: 9000
      targetPort: 9000
    - name: console-ui
      protocol: TCP
      port: 9001
      targetPort: 9001
  selector:
    role: minio
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: minio
spec:
  serviceName: "minio"
  replicas: 4
  selector:
    matchLabels:
      role: minio
      environment: test
  template:
    metadata:
      labels:
        role: minio
        environment: test
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: minio
          env:
            - name: MINIO_ROOT_USER
              value: blocMinio
            - name: MINIO_ROOT_PASSWORD
              value: blocMinioPasswd
          image: minio/minio:RELEASE.2021-11-24T23-19-33Z
          resources:
            requests:
              ephemeral-storage: 2Gi
          imagePullPolicy: IfNotPresent
          args:
            - server
            - http://minio-{0...3}.minio.default.svc.cluster.local/data
            - --address 
            - :9000
            - --console-address 
            - :9001
          ports:
            - containerPort: 9000
              name: api
            - containerPort: 9001
              name: console-ui
          volumeMounts:
            - name: minio-vct
              mountPath: /data
  volumeClaimTemplates:
    - metadata:
        name: minio-vct
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 2Gi
```

2. 使用以下命令**启动服务**：
```shell
$ kubectl create -f bloc-minio.yaml
```

3. 使用以下命令**检查服务是否启动完成**了：
```shell
$ kubectl get pods
NAME          READY   STATUS    RESTARTS   AGE
minio-0       1/1     Running   0          8m38s
minio-1       1/1     Running   0          8m35s
minio-2       1/1     Running   0          8m27s
minio-3       1/1     Running   0          8m25s
mongo-0       1/1     Running   0          5h4m
rabbit-0      1/1     Running   0          128m
```
在其中看到`minio-0...3`的`STATUS`值为`Running`就知道是启动成功了

这里还可以看下日志：
```shell
$ kubectl logs minio-0
Waiting for atleast 1 remote servers to be online for bootstrap check
Following servers are currently offline or unreachable [http://minio-1.minio.default.svc.cluster.local:9000/data http://minio-2.minio.default.svc.cluster.local:9000/data http://minio-3.minio.default.svc.cluster.local:9000/data]
.
.
.
Waiting for atleast 1 remote servers to be online for bootstrap check
Waiting for all MinIO sub-systems to be initialized.. lock acquired
Verifying if 1 bucket is consistent across drives...
Automatically configured API requests per node based on available memory on the system: 5
All MinIO sub-systems initialized successfully
Waiting for all MinIO IAM sub-system to be initialized.. lock acquired
Status:         4 Online, 0 Offline. 
API: http://172.17.0.2:9000  http://127.0.0.1:9000 

Console: http://172.17.0.2:9001 http://127.0.0.1:9001 
.
.
.
```
可以看到日志写到4个服务都在线了

4. 服务有效性检验：
和rabbitMQ一样，minio也是有前端管理界面且我们都打开了的（--console-address指定的就是前端管理界面的port）

那么我们同样可以通过登陆管理界面来看看集群的状态：
```shell
# 查看minio-read service是否在线
$ kubectl get svc
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP              4d15h
minio         ClusterIP   None            <none>        9000/TCP,9001/TCP    4m20s
minio-read    ClusterIP   10.98.192.184   <none>        9000/TCP,9001/TCP    4m20s
mongo         ClusterIP   None            <none>        27017/TCP            5h
mongo-read    ClusterIP   10.109.241.29   <none>        27017/TCP            5h
rabbit        ClusterIP   None            <none>        5672/TCP,15672/TCP   124m
rabbit-read   ClusterIP   10.98.131.195   <none>        5672/TCP,15672/TCP   124m
------------------------------------------------------------
# 通过minikube service命令在宿主机访问服务
$ minikube service minio-read
|-----------|------------|-------------|--------------|
| NAMESPACE |    NAME    | TARGET PORT |     URL      |
|-----------|------------|-------------|--------------|
| default   | minio-read |             | No node port |
|-----------|------------|-------------|--------------|
😿  service default/minio-read has no node port
🏃  Starting tunnel for service minio-read.
|-----------|------------|-------------|------------------------|
| NAMESPACE |    NAME    | TARGET PORT |          URL           |
|-----------|------------|-------------|------------------------|
| default   | minio-read |             | http://127.0.0.1:56779 |
|           |            |             | http://127.0.0.1:56780 |
|-----------|------------|-------------|------------------------|
🎉  Opening service default/minio-read in default browser...
🎉  Opening service default/minio-read in default browser...
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```

然后在宿主机浏览器通过上面输出的地址`http://127.0.0.1:56780`就能够访问到管理界面了：
![minio management UI Login](/static/local_deployment_minio_ui_login.png)
通过yaml文件里配置的用户/密码（blocMinio/blocMinioPasswd）登陆后：
![minio management UI dashboard](/static/local_deployment_minio_ui_dashboard.png)
通过dashboard可以看到4个节点都是在线的

## 部署bloc-server
> 如果你准备开发的是各个语言的Client-SDK 或 frontend，那么bloc-server是稳定不需要变动

1. **创建以下yaml文件**，假设叫`bloc-server.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: bloc-server
  labels:
    name: bloc-server
spec:
  ports:
    - port: 8000
      targetPort: 8000
  selector:
    role: bloc-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bloc-server
spec:
  replicas: 1
  selector:
    matchLabels:
      role: bloc-server
      environment: test
  template:
    metadata:
      labels:
        role: bloc-server
        environment: test
    spec:
      containers:
        - name: bloc-server
          image: billiepander/bloc_server:v8
          command:
          - "/app/main"
          args: 
          - "--app_name"
          - "local"
          - "--rabbitMQ_connection_str"
          - "blocRabbit:blocRabbitPasswd@rabbit-read:5672"
          - "--minio_connection_str"
          - "pdblocminio:pdblocminiotony@minio-read:9000"
          - "--mongo_connection_str"
          - ":@mongo-read:27017"
          ports:
            - containerPort: 8000
              name: bloc-server-api
```

2. 使用以下命令**启动服务**：
```shell
$ kubectl create -f bloc-server.yaml
```

3. 使用以下命令**检查服务是否启动完成**了：
```shell
$ kubectl get po
NAME                           READY   STATUS    RESTARTS   AGE
bloc-server-785784c8fd-mc4xb   1/1     Running   0          2m21s
minio-0                        1/1     Running   0          7h39m
minio-1                        1/1     Running   0          7h39m
minio-2                        1/1     Running   0          7h39m
minio-3                        1/1     Running   0          7h39m
mongo-0                        1/1     Running   0          12h
rabbit-0                       1/1     Running   0          9h
```
备注：`bloc-server-xxx`是上面的`bloc-server-785784c8fd-mc4xb`, 但是你的输出可能不是这个值，所以以`bloc-server-xxx`代替

其中看到的`bloc-server-xxx`的`STATUS`为`Running`了，就是启动成功了

如果有ERROR，使用`docker pull billiepander/bloc_server:v8`检查下镜像是不是拉取成功的。如果镜像拉取成功还是启动失败，可通过`kubectl logs bloc-server-xxx`来看看具体的日志

4. 服务有效性检验：
既然是server，那么就通过访问其http api来验证下有没有部署成功吧

首先还是通过`minikube service $service_name`来生成一个宿主机可以访问的地址：
```
~ » minikube service bloc-server
|-----------|-------------|-------------|--------------|
| NAMESPACE |    NAME     | TARGET PORT |     URL      |
|-----------|-------------|-------------|--------------|
| default   | bloc-server |             | No node port |
|-----------|-------------|-------------|--------------|
😿  service default/bloc-server has no node port
🏃  Starting tunnel for service bloc-server.
|-----------|-------------|-------------|------------------------|
| NAMESPACE |    NAME     | TARGET PORT |          URL           |
|-----------|-------------|-------------|------------------------|
| default   | bloc-server |             | http://127.0.0.1:59841 |
|-----------|-------------|-------------|------------------------|
```

OK，通过上面我们看到`bloc-server`的可访问地址是`http://127.0.0.1:59841`, 那么通过`curl`访问下登陆api试试：
```shell
curl --location --request POST '127.0.0.1:59841/api/v1/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "name": "bloc",
    "password": "maytheforcebewithyou"
}'
{"status_code":200,"status_msg":"","data":{"name":"bloc","password":"","token":"4f2a6fec-9dfc-4f82-97f3-3f8d56e6110d","id":"","create_time":"2022-01-02T22:01:24+08:00","super":true}}
```
可以看到访问的返回是：
```json
{
    "status_code": 200,
    "status_msg": "",
    "data": {
        "name": "bloc",
        "password": "",
        "token": "4f2a6fec-9dfc-4f82-97f3-3f8d56e6110d",
        "id": "",
        "create_time": "2022-01-02T22:01:24+08:00",
        "super": true
    }
}
```
就是成功啦！

## 部署bloc-frontend
#todo

## 部署bloc-client-go
#todo

## 部署bloc-client-python
#todo