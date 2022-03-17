> 1.0版本暂未上线，但是快了，敬请期待 =_=
# Bloc
## 目标
Bloc 是一个致力于**将开发者从需求变化中解放出来**的工作流管理平台

## 核心思想
首先需要说明的是，bloc考虑的情况是包括开发者、开发者领导、开发者同事、运营、产品等的整体情况。

其次，这里讨论的范围是工作流场景，不是server端的情况。

再其次，我们应有以下共识：
1. 一个程序任务，是由多个步骤串联而成的。这里的步骤可以看作为一个函数
2. 不同任务之间的区别可能是包含的 步骤不一样 或 步骤的顺序不一样 或 步骤顺序完全一样、只是其中一个或多个函数的参数输入不一样
3. 任务的执行安排是会经常改变的（比如把A任务放到B任务之后执行，暂停C任务一段时间）
4. 如果控制逻辑的参数都写死在代码里，将会出现
	1. 黑盒问题：可能会一直有人来反复找你确认某个参数是不是xxx（其预想的值）【这种来问的最多的应该是运营人员】
	2. 沟通成本：可能有不同的/新的关心这个任务的人（离职、交接等情况），来找你了解任务中某项的具体参数是什么
	3. 参数的变化是较为频繁的，将会每次都需要通过开发者修改来进行
	4. 共享成本：开发者间如何方便的共享开发的函数的能力

最后，**bloc解决这些问题的思想是什么**？

bloc认为，在大多情况里，一个函数的功能是能够通过参数来控制与改变的，如果开发者在开发每个功能函数时，将能够控制此函数功能的部分全部提炼为参数暴露出来、且配上易懂的解释。那么bloc认为此函数的含义及其最后的功能表现就可以脱离开发者了。

假设有满足上面情况的一个函数池，那么用户在函数池里面可以自己通过阅读函数及其参数的描述明白每个函数能提供的“原子功能”。从而用户可以从中挑选出需要的函数并为每个函数设置其所需的参数来组合形成一个任务，也就是不同的用户可以根据自己的需求来自行组合自己的任务。

而bloc要做的事情就是承接开发者开发的函数形成函数池，而后面向用户提供这些函数、支持用户基于这些函数来编排自己的任务，并且通过设置运行参数来触发任务的运行。

也就是说，bloc希望开发者**只需**集中精力开发好每个功能函数（并且将影响函数运行的参数都暴露出来）**剩下的就都不用管了**。使用者（这里的使用者可能是开发者自己、运营人员、管理者...）自行通过bloc来操控函数块的串联方式、编写各个函数块的参数输入、设置与编排任务的运行来满足使用者的需求。

示意图：
![after_bloc](/static/after_bloc.png)

最后，如果还是感觉完全不明白在说什么，可以参考一些[实际的举例](/example.md)
## 项目概述
### 项目组件说明
![component](/static/bloc_component.svg)

[`bloc-frontend`](https://github.com/fBloc/bloc-frontend)：bloc前端界面。用户可以直接在此界面查看已有的函数，基于函数编排成任务并自定义其中各个函数的参数（目前支持手动写死值、*将上游函数的输出设置为输入*、触发时再动态覆盖 三种方式），配置各个任务的运行方式（crontab、http、任务间执行顺序编排），查看任务每次运行信息及其各个函数输入输出的具体值...

[`bloc-client-go`](https://github.com/fBloc/bloc-client-go)：开发者如果想开发go语言的函数，需基于此SDK进行开发

[`bloc-client-python`](https://github.com/fBloc/bloc-client-python)：开发者如果想开发python语言的函数，需基于此SDK进行开发

[`bloc-server`](https://github.com/fBloc/bloc-server)：为前端界面提供api、为client提供函数注册中心、调度及发配任务及函数的运行（包括触发重试、接收心跳等...）...

**整体概述**：开发者首先需部署`bloc-frontend`和`bloc-server`作为bloc的基础环境。然后基于bloc-client-$programLanguage SDK开发自己的函数并运行，此时运行起来的client实例就会向`bloc-server`提交此实例所有的函数（同理、别的client实例可以向同一个`bloc-server`进行提交）（client与`bloc-server`交互的功能是SDK实现的，开发者只需要开发自己函数相关的逻辑就行）。而后用户就能在`bloc-frontend`前端就能够看到所有的函数（可能背后是来自不同语言、不同仓库部署而成的client实例），并且对在前端对这些函数进行编排成任务、设置函数参数、设置运行方式...。 设置好后`bloc-server`会根据配置的信息进行触发运行，当特定函数需要运行时，`bloc-server`会根据用户在前端配置的参数计算好此函数的输入值，并发布信息到有此函数的client实例，有此函数的client接收到触发信息以及计算后的参数值后就执行运行并上报信息就是了（上报信息也是SDK完成的），`bloc-server`接收到运行信息后会记录并展示到`bloc-frontend`前端项目
### feature✨
1.0版本的feature - 1.0版本的核心是在实现核心功能的情况下尽可能的打牢基础 💥：
1. 支持多语言的函数（目前支持[go](https://github.com/fBloc/bloc-client-go)、[python](https://github.com/fBloc/bloc-client-python)）。设计上遵循了重bloc-server、轻client的策略，降低实现新语言SDK的复杂度
2. 支持跨代码仓库的函数提供（跨语言、跨仓库、跨团队提供的功能函数，只要配置的bloc-server地址是同一个，都可以一起展现在前端并被编排【同一任务中的函数可以是来自不同仓库、不同语言提供的函数！】。再也不用头破血流的到处去问组内/别的团队有没有提供特定功能了！）
3. 支持水平扩展运行函数块（非直接上下游依赖关系的函数可并行运行，部署的client实例越多并行度就越大）。client部署的实例是无状态的，其收到运行其下某个函数的命令时（函数所需的输入参数值也会传递进来）只需要执行运行并上报运行相关信息就是了，其并不知道也不需要知道运行的这个函数是属于某个flow的，这些都会在`bloc-server`中进行管理，所以可以水平扩展
4. 分布式与高可用：通过上面已经知道了client实例是可以“无限”水平扩展部署的，其不会出现多部署重复消费的问题。`bloc-server`也是可以多机部署的，在多机部署的情况下不会出现比如重复触发任务、重复触发重试等问题。`bloc-frontend`作为前端项目不存在这个问题、可以多机部署。
5. 任务执行时机编排同时支持手动触发、周期（crontab）触发、Webhook触发
6. 较为丰富的函数参数输入方式：
	1. 可在前端手动输入写死的值
	2. 可在前端通过连线的方式将特定上游某函数的输出作为此函数的某个参数输入
	3. Api触发时支持动态覆盖函数输入（可实现基于事件动态值触发任务运行）
7. 较为完备的日志系统
	1. 用于debug：各项操作都有完备的日志。以运行一个任务为例，能够查询到其生命周期里的全部日志（可获取到其从触发到运行结束中各个环节【即使跨机器等分布式场景】的全部日志，环节包括并不限于 - 触发环节的日志、调度器调度的日志、client运行时候的心跳日志、client上报的运行信息日志...）【嗯，如果没有完备的日志谁敢用于生产呢？】
	2. 用于查看函数实时运行信息：对于任务中正在运行的函数，能够查看其实时日志/进度（主要是为了避免用户来问开发者某个长时间运行的任务是不是死了、浪费开发者精力）
8. 支持函数输入输出数据量较为大的任务：为避免使用关系型数据库或者NoSQL可能存储的函数输入输出值太大带来的性能问题，引入了对象存储相关的库来单独存储函数运行时的输入输出，故除非你的函数输入输出值大大大！否则没问题
9. 较为完备的重试机制：bloc-server会管理对于运行失败或者运行时程序异常退出的自动重试（支持在前端设置重试策略）
10. 出乎意料的高复用性：基于现在的架构方式，除了可直接复用向同一个bloc-server提交注册的client实例里的函数，bloc后续也可很方便的对于常见的通用的需求直接开发好对应的function，用户可开箱即用
11. 较为完备的权限管理：功能函数以及任务都可以设置RWE等权限，可以不同粒度的做隔离


2.0版本的feature - 2.0版本的核心是全覆盖各种工作流情景 🛫️：
1. 支持订阅机制：可订阅另一个任务中的某个函数，当对应函数运行时自动触发此任务。
2. 支持审批机制：比如任务中的某个函数不能直接运行、需要等待“审批”通过与否后才决定是否自动执行后续函数。后置到2.0版本实现
3. 支持可视化编排任务间运行关系
4. 丰富富参数的输入方式

3.0版本的feature - 3.0版本的核心是“开疆扩土” 🔭：
1. 支持long run server function

## 快速上手
[快速上手文档](/docs/guide/zh-CN/quickstart/quck-start.md)

## 生产环境部署指南
- todo

## 贡献指南
- todo
