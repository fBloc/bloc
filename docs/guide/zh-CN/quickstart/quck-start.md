> 本文的主要目的有两个:
> 1. 介绍如何快速上手使用bloc
> 2. 基于本文所用的例子，希望能表达出基于bloc开发所带来的优势

# 准备bloc基础环境
> 前提：需要机器已安装了 `docker` 以及 `docker-compose` 以及确保 `wget` 命令 是存在的。如果没有的话请先自行安装

1. 切换到一个新的目录
```shell
$ cd ~ && mkdir -p bloc && cd bloc
```

2. 下载启动的 shell 文件
```shell
$ wget https://cdn.jsdelivr.net/gh/fBloc/bloc@main/docs/guide/zh-CN/quickstart/startup.sh
```
完成后当前目录下应该有名为 startup.sh 的文件

3. 启动 bloc
```shell
$ /bin/bash startup.sh
```
看到最后输出 `All ready!` 就表示启动成功了！

# 基于bloc开发
> 假设我们刚进入一个才开业的**屠宰公司**的开发团队
>> 备注：本文故意选择这种抽象的、所有人都能直接明白的背景来进行说明，以避免直接使用特定业务场景（如电商）带来的不通感。相信最后您看完后能够结合您自己的业务来思考是否适用/怎么用
## Go的开发例子
假设我们收到的第一个需求是：把这头大象放进冰箱

如果常规的开发写一个脚本，其中两步就是 1: 取这头大象；2: 放进冰箱；完成

但是可能不久用户就会有新需求：
1. 要求把另一头大象/牛/羊放进冰箱
2. 具体要求什么时间放进冰箱
3. 具体要求什么时间/放进冰箱多久后从冰箱取出来
4. 扩展一个屠宰需求？？

出于考虑扩展性，屠宰需求先不管（稍后会写如果加入的话、使用bloc能带来的优势）、剩下的拆分为两个函数块：
1. 「选择动物」：参数有1. 选择源头的动物类型（必填）；2. 具体动物的id（必填）
2. 「冰箱操作」：参数有1. 什么时间放入（必填）；2. 放入后多久时间取出（选填）；3. 什么时间取出（选填）

好了，那我们就开始开发这两个函数了：

先clone[仓库](https://github.com/fBloc/bloc-examples)

然后进入项目的路径：`$ cd xxx/bloc-examples/go/bloc_tryout_go`

目录树如下：
```shell
~/bloc-examples/go/bloc_tryout_go(main) » tree .
.
├── function
│   ├── choose_animal.go  # 选择动物 函数
│   └── fridge.go  # 冰箱操作 函数
├── main.go  # 运行入口
```
其中我们开发的两个函数分别就在：[function/choose_animal.go](https://github.com/fBloc/bloc-examples/blob/main/go/bloc_tryout_go/function/choose_animal.go) 和 [function/fridge.go](https://github.com/fBloc/bloc-examples/blob/main/go/bloc_tryout_go/function/fridge.go)

这两个函数主要就是需要实现`FunctionDeveloperImplementInterface`这个interface下的方法：
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

查看 [main.go](https://github.com/fBloc/bloc-examples/blob/main/go/bloc_tryout_go/main.go):
```go
func main() {
	client := bloc_client.NewClient("quickStart-go")

	// 配置用到的后端组件
	client.GetConfigBuilder().SetRabbitConfig(
		"blocRabbit", "blocRabbitPasswd", []string{"localhost:5672"}, "",
	).SetServer(
		"127.0.0.1", 8080,
	).BuildUp()

	// 导入分组的全部function节点
	sourceFunctionGroup := client.RegisterFunctionGroup("动物源")
	sourceFunctionGroup.AddFunction("选择动物", "从数据库选择动物", &function.ChooseAnimal{})

	triggerFunctionGroup := client.RegisterFunctionGroup("处理中心")
	triggerFunctionGroup.AddFunction("冰箱", "接收物体放入冰箱冰记录出冰箱时间", &function.Fridge{})

	client.Run()
}
```
可以看到的是，其实就做了两件事：
1. 配置bloc-server地址 & 配置rabbitMQ地址
2. 注册开发的函数（注意这里需要将函数分组、提供函数的名字和描述信息。更为方便用户在前端知道这个函数的作用）

然后运行项目：
```shell
~/bloc-examples/go/bloc_tryout_go(main*) » go run main.go
```

不报错就表示运行成功！

- todo 访问前端界面检测到此两个函数已经成功注册
接下来可以去前端 先通过默认的用户名/密码: bloc/maytheforcebewithyou登陆。

**此时开发者的工作就完了，接下来我们来模拟使用者是怎么在前端使用bloc的来看看效果**

### 模拟使用者
- todo 等待前端部署进来

# Python语言的开发
- todo
