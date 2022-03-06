
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

**好啦，到现在，bloc基础环境(图一)就搭建完成啦！下面来愉快的开发吧！**
图2:

![bloc_user_deployment_full](/static/bloc_user_deployment_full.png)

# 开发你的函数
## Go语言的开发例子
假设我们收到个需求：把这头猪放进冰箱

如果常规的开发写一个脚本，其中两步就是1: 取这头猪；2: 放进冰箱；完成

但是可能不久用户就会有新需求：
1. 要求把另一头猪/牛/羊放进冰箱
2. 具体要求什么时间放进冰箱
3. 具体要求什么时间/放进冰箱多久后从冰箱取出来
4. 扩展一个屠宰需求？？

出于合理考虑扩展性，屠宰需求先不管（稍后会写如果加入的话、使用bloc能带来的优势）、剩下的拆分为两个函数块：
1. 「选择动物」：参数有1. 选择源头的动物类型（必填）；2. 具体动物的id（必填）
2. 「冰箱操作」：参数有1. 什么时间放入（必填）；2. 放入后多久时间取出（选填）；3. 什么时间取出（选填）

好了，那我们就开始开发这两个函数了：

先clone[仓库](https://github.com/fBloc/bloc-examples)

然后进入项目的路径：`$ cd xxx/bloc-examples/go/bloc_tryout_go`

目录树如下：
```shell
~/bloc-examples/go/bloc_tryout_go(main) » tree .
.
├── README.md
├── function
│   ├── choose_animal.go  # 选择动物 函数
│   └── fridge.go  # 冰箱操作 函数
├── go.mod
├── go.sum
├── main.go  # 运行入口
├── model
│   └── animal
│       └── animal.go  # 访问数据库
└── static
    └── animal.json  # 模拟动物数据库的数据
```
其中我们开发的两个函数分别就在：[function/choose_animal.go](https://github.com/fBloc/bloc-examples/blob/main/go/bloc_tryout_go/function/choose_animal.go)和[function/fridge.go](https://github.com/fBloc/bloc-examples/blob/main/go/bloc_tryout_go/function/fridge.go)

请先分别进两个函数去看看，其实其就是需要实现`FunctionDeveloperImplementInterface`这个interface下的方法：
```go
type FunctionDeveloperImplementInterface interface {
	Run(
		context.Context,  // 可根据此来取消自己的运行（比如用户在前端取消了整个的运行）
		Ipts,  // 每次运行、获取到输入参数具体值后的Ipt
		chan HighReadableFunctionRunProgress,  // 用于向server上报进度的channel
		chan *FunctionRunOpt,  // 用于向server上报运行完毕的结果的channel
		*Logger,  // 打运行日志（会自动定时向server传输、从而能看到运行的“实时”日志）
	)  // 实际的Run方法
	IptConfig() Ipts  // 输入参数描述
	OptConfig() []*Opt  // 输出参数描述
	AllProcessStages() []string  // 处理过程阶段的标识
}
```

好了，目前我们已经自己实现了两个函数了，那要怎么`run`起来呢？

来看看[main.go](https://github.com/fBloc/bloc-examples/blob/main/go/bloc_tryout_go/main.go):
```go
package main

import (
	"bloc_tryout_go/function"

	bloc "github.com/fBloc/bloc-client-go"
)

const appName = "tryout"

func main() {
	blocClient := &bloc.BlocClient{Name: appName}

	// 下面两个修改为你本地具体的port
	rabbitMQPort := 0
	serverPort := 0
	// 配置用到的后端组件
	blocClient.GetConfigBuilder().SetRabbitConfig(
		"blocRabbit", "blocRabbitPasswd", "127.0.0.1", rabbitMQPort, "",
	).SetServer(
		"127.0.0.1", serverPort,
	).BuildUp()

	// 导入分组的全部function节点
	sourceFunctionGroup := blocClient.RegisterFunctionGroup("动物源")
	sourceFunctionGroup.AddFunction("选择动物", "从数据库选择动物", &function.ChooseAnimal{})

	triggerFunctionGroup := blocClient.RegisterFunctionGroup("处理中心")
	triggerFunctionGroup.AddFunction("冰箱", "接收物体放入冰箱冰记录出冰箱时间", &function.Fridge{})

	blocClient.Run()
}
```
可以看到的是，其实就做了两件事：
1. 配置bloc-server地址 & 配置rabbitMQ地址
2. 注册开发的函数（注意这里需要将函数分组、提供函数的名字和描述信息。更为方便用户在前端知道这个函数的作用）

好了，上面[搭建bloc基础环境](#搭建bloc基础环境)那个步骤我们已经搭建好了需要的东西了，现在只需要使用就是了。

这里还是使用`minikube service`命令来暴露宿主机可访问的地址：
```shell
# 开启minio/rabbit/mongo部署的外部可访问。
# 其中第二条url是rabbitMQ的amqp协议（与bloc-infra-read service定义的顺序一致）
$ minikube service bloc-infra-read --url
🏃  Starting tunnel for service bloc-infra-read.
|-----------|-----------------|-------------|------------------------|
| NAMESPACE |      NAME       | TARGET PORT |          URL           |
|-----------|-----------------|-------------|------------------------|
| default   | bloc-infra-read |             | http://127.0.0.1:56433 |
|           |                 |             | http://127.0.0.1:56434 |
|           |                 |             | http://127.0.0.1:56435 |
|           |                 |             | http://127.0.0.1:56436 |
|           |                 |             | http://127.0.0.1:56437 |
|-----------|-----------------|-------------|------------------------|
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.

# 开启bloc-server/bloc-frontend部署的外部可访问。
# 其中第一条url是bloc-server的（与bloc-server-and-ui service定义的顺序一致）
$ minikube service bloc-server-and-ui --url
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
| default   | bloc-server-and-ui |             | http://127.0.0.1:56347 |
|           |                    |             | http://127.0.0.1:56348 |
|-----------|--------------------|-------------|------------------------|
```

好了，那么将`main.go`中修改如下：
```go
rabbitMQPort := 56434
serverPort := 56347
```

然后运行项目：
```shell
~/bloc-examples/go/bloc_tryout_go(main*) » go run main.go

```

不报错应该就没问题了，我们来检查下开发的函数是否成功的注册进去了。

此时在浏览器访问上面通过`minikube service bloc-server-and-ui --url`暴露出来的`bloc-frontend`的地址：`http://127.0.0.1:56348`：

先通过默认的用户名/密码: bloc/maytheforcebewithyou登陆。

然后点击查看函数就能看到这两个函数已经成功注入啦(也就是图2的部分都完成啦)：
- todo 补充前端显示此两个函数的图

**此时开发者的工作就完了，接下来我们来模拟使用者是怎么在前端使用bloc的来看看效果**

### 模拟使用者
- todo 等待前端部署进来

# Python语言的开发
- todo
