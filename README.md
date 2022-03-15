> 1.0版本暂未上线，但是快了，敬请期待 =_=
# Bloc
## 目标
Bloc 是一个致力于**将开发者从需求变化中解放出来**的工作流管理平台

## 核心思想
首先，我们应该会有以下的共识：
1. 一个程序任务，是由多个步骤串联而成的。这里的步骤可以看作为一个函数
2. 不同任务之间的区别可能只是步骤的顺序不一样，甚至是步骤顺序完全一样、只是其中一个或多个函数的参数输入不一样
3. 任务的执行安排也是会经常改变的（比如把A任务放到B任务之后执行，暂停C任务一段时间）
4. 如果控制逻辑的参数都写死在代码里，将会出现
	1. 黑盒问题：可能会一直有人来反复找你确认某个参数是不是xxx（其预想的值）
	2. 沟通成本：可能有不同的/新的关心这个任务的人（离职、交接等情况），来找你了解任务中某项的具体参数是什么
	3. 参数的变化是较为频繁的，将会每次都需要通过开发者修改来进行
5. ...

bloc 是如何解决这些问题的？
bloc 基于的核心思想是：开发者**只需**要开发好每个函数，并且将影响函数运行的参数（在项目中扩展为了"富参数"、支持更为广泛）都暴露出来。**剩下的就都不用管了**。使用者（这里的使用者可能是自己、运营人员、管理者...）通过bloc前端界面来操控函数块的串联方式、编写各个函数块的参数输入、设置与编排任务的运行来满足使用者的需求。

### 示意图
> #todo 此两个图较乱、需重绘

使用bloc前的开发流程（从最开始为单个需求开发的简单脚本，演进到后面的庞杂交织的应用。事无巨细的需求变化和沟通成本，都需要通过开发者，耗费开发者大量精力）：
![before_bloc](/static/before_bloc.png)

使用了bloc后，能最大程度的**解耦需求变化**和**降低沟通成本**（需求变化和信息最大程度的能直接在bloc前端获取或修改）：
![after_bloc](/static/after_bloc.png)

## 项目概述
### 项目组件
![component](/static/bloc_component.svg)

[`bloc-frontend`](https://github.com/fBloc/bloc-frontend)：bloc前端界面。用户可以直接在此界面查看已有的函数，基于函数编排成任务并自定义其中各个函数的参数（目前支持手动写死值、*将上游函数的输出设置为输入*、触发时再动态覆盖 三种方式），配置各个任务的运行方式（crontab、http、任务间执行顺序编排），查看任务每次运行信息及其各个函数输入输出的具体值...

[`bloc-client-go`](https://github.com/fBloc/bloc-client-go)：开发者如果想开发go语言的函数，需基于此库进行开发

[`bloc-client-python`](https://github.com/fBloc/bloc-client-python)：开发者如果想开发python语言的函数，需基于此库进行开发

[`bloc-server`](https://github.com/fBloc/bloc-server)：为前端界面提供api、为client提供函数注册中心、调度及发配任务及函数的运行（包括触发重试、接收心跳等...）...
### feature✨
项目有以下feature：
1. 支持多语言的函数（目前支持[go](https://github.com/fBloc/bloc-client-go)、[python](https://github.com/fBloc/bloc-client-python)）。而且从设计上就遵循了重bloc-server、轻client的策略，降低实现新语言SDK的复杂度
2. 支持跨代码仓库的函数提供（跨编程语言、跨仓库、跨团队提供的函数都可以一起在前端被编排【**同一任务中的函数可以是来自不同仓库、不同语言提供的函数**！】）
3. 支持水平扩展运行函数块（非直接上下游依赖关系的函数可并行运行，部署的client实例越多并行度就越大）。client实例是无状态的，其只需要收到运行的命令就运行就是了，会把函数输入也传递进来，所以可以水平扩展
4. 任务执行时机编排同时支持周期（crontab）、Webhook触发、~~以及任务间先后依赖顺序指定的方式.后置到2.0再实现~~
5. 较为丰富的函数参数输入方式：用户可在前端手动输入函数的输入参数、可在前端通过连线的方式将函数特定上游某函数的输出作为此函数的某个参数输入、Api触发时支持动态覆盖函数输入
6. 较为完备的日志系统
	1. 用于debug：各项操作都有完备的日志。以运行一个任务为例，能够查询到其生命周期里的全部日志（可获取到其从触发到运行结束其中各个环节【即使跨机器等】的全部日志，环节包括并不限于 - 触发环节的日志、调度器调度的日志、client运行时候的心跳日志、client上报的运行信息日志...）
	2. 用于查看函数实时运行信息：对于任务中正在运行的函数，能够查看其实时日志
7. 支持函数输入输出数据量较为大的任务：为避免使用关系型数据库或者NoSQL可能存储的函数输入输出值太大带来的性能问题，引入了对象存储相关的库来单独存储函数运行时的输入输出，故除非你的函数输入输出值大大大！否则没问题
8. 较为完备的重试机制：bloc-server会管理对于运行失败或者运行时程序异常退出的自动重试（支持在前端设置重试策略）
9. ~~支持订阅另一个任务中的某个函数，当期每次运行时触发此任务。后置到2.0再实现~~


<!-- ## 一个例子
假设是一个学校

假设年纪主任要找全年级平均成绩最高的几个学生来开家长会，那么会有以下的工作流：
![flow example](/static/flow_example.png)

`学生直接输入节点` - 此节点过滤学生输入源（如下面只要六年级的学生）：
![flow example](/static/user_ipt.png)

`计算成绩` - 根据输入的学生，以及配置的计算方式和挑选规则选出特定的学生：
![flow example](/static/score_calcu.png)

`电话通知` - 对特定学生，电话通知输入的特定内容：
![phone call](/static/phone_call.png)

通过这个例子我们来看看基于bloc构建，带来了哪些优势：
1. 参数变化，举例：
	1. 如果第二天年纪主任改需求了，突然想找数学成绩最差的同学来开会 - 只需要将`计算成绩`节点中的学科选项选成数学再触发一次即可（开发者不需要参与）
2. 功能组合变化，举例：
	1. 如果第二班的老师看到了这个工作流，想看看看自己班的情况 - 只需要将此工作流fork一份到自己，然后将`学生直接输入节点`里面的班级过滤添加个二班再跑一次即可（开发者不需要参与）
2. 透明性问题，举例：
	1. 假如第二班的班主任突然发现年纪主任找自己的学生谈话了，那么如果其想要查看年级主任是依据什么来找家长的，其就可以直接在前端看出来，`计算成绩`节点里面配置了是根据「没有过滤学科」+「平均值」的计算方式过滤的，这样二班班主任直接就知道了年级主任是依据各科的平均分来找的（开发者不需要参与 & 也不需要找年级主任确定）
	2. 同理，第二班的班主任也直接能够通过这个的运行输出直接看出来找了哪些同学（从而看哪些是自己班的 - 甚至还可以fork这个工作流过来，再在最后的函数块后面加一个过滤节点来筛出来自己班的）
3. 扩展性：
	1. 假设现在突然教育部要求，每个孩子每晚要测体温进行上报，超过xx度的第二条不能上学，那么只需要添加一个体温输入的节点，并且为之设置好规则:
	![high_temp_flow](/static/high_temp_flow.png)
	直接在前端设置了>37.5度的学生需要上报
	![high_temp_func](/static/high_temp_func.png)
	直接在前端配置运行时间
	![temp_crontab](/static/temp_crontab.png)
	这里就是对应了"运行变化"，对于想要停掉或者修改或者了解运行时机的人，直接在前端就可以操作了
	
	2. 又假设学校突然变人性化，希望在天气变化比较大的时候提醒学生注意保暖
	可以构建如下的工作流
	![extrem weather flow](/static/extrem_weather_flow.png)
	特别说明：图中的第一层的三个节点是会并行运行的 -->

<!-- 4. 进阶版运行控制
//todo 说明基于arrangement的工作流上下游编排 -->

<!-- ## 一些feature说明
// todo -->

<!-- 
## 使用流程概述
1. 用户基于对应编程语言(目前只有go)的SDK开发函数，形成一个`函数块`。SDK会要求函数实现以下的几个方法：
	1. 函数本身描述：说明函数本身的作用
	2. 输入描述：尽可能的将变化和控制**都**通过"参数"暴露出来作为控制函数运行的`富输入参数`
	3. 输出描述：将每个输出都进行说明
	4. Run方法：用于实际执行时被调用
2. 使用者直接在前端通过DAG拖拽`函数块`的方式构建`工作流`。特别注意的一点就是，这里不止是拖拽函数块就完了，而是还支持用户配置`函数块`的入参，而且入参不仅支持手动输入特定值、还支持将上游`函数块`的某个特定输出直接作为此函数的某参数的输入值！（这就是）
3. 构建好的`工作流`支持三种运行模式：
	1. 直接为此工作流配置`crontab表达式`以周期运行
	2. 直接为此工作流配置`触发key`，可通过调用http api并提供此key来触发此flow的运行
	3. 以`工作流`作为块，以DAG的方式构建`运行编排`。从而实现处理类似此工作流需要某工作流先完成的需求 -->
## 快速上手
<!-- [快速上手文档](/docs/guide/zh-CN/quickstart/quck-start.md) -->

### 准备bloc基础环境
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

### 基于bloc开发
> 假设我们刚进入一个才开业的**屠宰公司**的开发团队
>> 备注：本文故意选择这种抽象的、所有人都能直接明白的背景来进行说明，以避免直接使用特定业务场景（如电商）带来的不通感。相信最后您看完后能够结合您自己的业务来思考是否适用/怎么用
#### Go的开发例子
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

##### 模拟使用者
- todo 等待前端部署进来

### Python语言的开发
- todo

- todo 视频演示

<!-- 
## 开发者文档
阅读对象：`bloc`开发者

- [本地开发/测试环境搭建指南](/docs/devel/zh-CN/local-dev-enviroment.md)
- #todo 期望开发的功能
- #todo 生产环境搭建建议 -->
