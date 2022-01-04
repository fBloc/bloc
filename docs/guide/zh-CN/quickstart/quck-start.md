本文讲解的对象是想使用bloc的开发者（不是要开发bloc的开发者）

假设其刚接触到bloc，想要在本地试一下

本文介绍的是通过`mikikube`搭建本地开发环境

# 安装minikube
安装minikube的官方指导见[doc](https://minikube.sigs.k8s.io/docs/start/)

有几点说明下：
1. 要求你本机先安装并启动了docker，如果没有安装，请先安装
2. 要求安装机满足以下条件:
    1. 2 CPUs or more
    2. 2GB of free memory
    3. 20GB of free disk space
    4. Internet connection
3. **安装/启动过程特别简单**，下载minikube后通过命令`minikube start`启动一个由1个节点构成的**kubernetes集群**

安装完成后可通过以下命令检查下状态:
```shell
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```
确保其中`host`、`kubelet`、`apiserver`都是`Running`

# 搭建bloc基础环境
> 到此步前请确保你的minikube已经安装好了

## 原理说明
此步骤搭建的环境其实就是在minikube中搭建了以下的环境：
图1:
![bloc_user_deployment_base](/static/bloc_user_deployment_base.png)

而接下来基于`bloc-client-xxLanguage`开发的函数就可以直接与之交互了：
图2:
![bloc_user_deployment_full](/static/bloc_user_deployment_full.png)

## 实际搭建
### 搭建需要用到的组件
将需要用到的minio/mongo/rabbitMQ部署在一起：

下载[bloc_infra.yaml](/docs/guide/zh-CN/quickstart/bloc_infra.yaml):

执行：
```shell
$ kubectl create -f bloc_infra.yaml
```

检查是否成功：
```shell
$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
bloc-infra-0           3/3     Running   0          69m
```
看到上面的`READY`是`3/3`就代表mongo/minio/rabbitMQ三个都部署完成了

### 搭建bloc-server和bloc-frontend
下载[bloc_server_and_ui.yaml](/docs/guide/zh-CN/quickstart/bloc_server_and_ui.yaml):

- TODO，补全bloc_server_and_ui里面frontend的部分

执行：
```shell
$ kubectl create -f bloc_server_and_ui.yaml
```

检查是否成功：
```shell
$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
bloc-infra-0           3/3     Running   0          69m
bloc-server-and-ui-0   1/1     Running   0          36m
```
看到上面的`bloc-server-and-ui-0`的`STATUS`是`Running`。就代表`bloc-server`和`bloc-frontend`都部署完成了

#### 验证`bloc-server`部署成功：
**开启宿主机可访问的地址**：
```shell
$ minikube service bloc-server-and-ui
|-----------|--------------------|-------------|--------------|
| NAMESPACE |        NAME        | TARGET PORT |     URL      |
|-----------|--------------------|-------------|--------------|
| default   | bloc-server-and-ui |             | No node port |
|-----------|--------------------|-------------|--------------|
😿  service default/bloc-server-and-ui has no node port
🏃  Starting tunnel for service bloc-server-and-ui.
|-----------|--------------------|-------------|------------------------|
| NAMESPACE |        NAME        | TARGET PORT |          URL           |
|-----------|--------------------|-------------|------------------------|
| default   | bloc-server-and-ui |             | http://127.0.0.1:53858 |
|           |                    |             | http://127.0.0.1:53859 |
|-----------|--------------------|-------------|------------------------|
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```

其两个地址分别是`bloc-frontend`和`bloc-server`的:
```shell
$ curl --location --request POST '127.0.0.1:53858/api/v1/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "name": "bloc",
    "password": "maytheforcebewithyou"
}
'
{"status_code":200,"status_msg":"","data":{"name":"bloc","password":"","token":"4ef8c9b0-20d6-431b-beb5-c6f8980e8fb8","id":"","create_time":"2022-01-04T21:20:26+08:00","super":true}}
```
通过上面的返回就知道`server-api`是部署成功的！

#### 验证`bloc-frontend`部署成功：
- TODO

**好啦，到现在，图一的就搭建完成啦！下面来愉快的开发功能吧！**

# 开发你的函数
## Go语言的开发例子

# Python语言的开发
#todo
