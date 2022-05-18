> 本文目标: 介绍如何快速在本地搭建一个bloc本地测试/开发环境 & 部署demo示例代码来尝鲜试用bloc

# 准备bloc基础环境
> 前提：需要机器已安装了 `docker` 以及 `docker-compose`。如果没有请先自行安装

1. 切换到一个新的目录
```shell
$ cd ~/tmp
```

2. Clone [bloc项目](https://github.com/fBloc/bloc)到本地 并 进入bloc目录
```shell
~/tmp $ git clone https://github.com/fBloc/bloc.git && cd bloc
```

3. 切换到相应路径
```shell
~/tmp/bloc $ cd docs/guide/zh-CN/quickstart
```

4. 运行安装文件
```shell
~/tmp/bloc/docs/guide/zh-CN/quickstart $ /bin/bash startup.sh
docker-compose.yml exist
docker-compose-bloc-server-mac.yml exist
docker-compose-bloc-server-linux.yml exist
shutdown.sh exist
bloc will use port 5672, 8080, 8083, 8086, 9000, 15672, 27017
Creating network "quickstart_default" with the default driver
Creating rabbit_bloc ... done
Creating influx_bloc ... done
Creating minio_bloc  ... done
Creating mongo_bloc  ... done
checking whether influxDB is ready
    Not ready
    ready!
start check whether minio is ready
    Not ready
    ready!
start check whether rabbitMQ is ready
    Not ready
    Not ready
    ready!
start check whether mongoDB is ready
    ready!
Starting bloc-server
bloc-server yaml file: docker-compose-bloc-server-mac.yml
Creating bloc_server ... done
    bloc-server is not up, retry
Starting bloc_server ... done
    bloc-server is up
Checking whether bloc-server is valid
    bloc-server is valid
Starting bloc_web, yaml file: docker-compose-bloc-web.yml
Creating bloc_web ... done
    bloc_web is up
******************************
All ready, Visit http://localhost:8083/ to visit bloc UI
```
此时顺利的话会自动在本地浏览器中打开地址：http://localhost:8083/, 也就是bloc-web ui的地址.

如果有失败你想清理下创建的container时，可运行：
```shell
~/tmp/bloc/docs/guide/zh-CN/quickstart $ /bin/bash shutdown.sh
```

# 基于bloc开发
上面一步、我们安装好了bloc环境，接下来就是开发我们自己的“函数”并进行提交到bloc了。

如果你是第一次使用bloc的话，请直接跟着下面的教程部署示例代码；如果你是老手的话，那可以把上面的环境当作本地开发测试环境进行自由的开发吧。

下面分别提供了相同功能实现的Go和Python示例。请选择一个你更熟悉的语言进行探索吧。

## Go语言示例
这里我们将模拟一个在股票公司工作的开发者，其需要为股票经理开发一些功能。

1. Clone [项目](https://github.com/fBloc/bloc-examples)到本地 并 进入相应目录
```shell
~/tmp $ git clone https://github.com/fBloc/bloc-examples.git && cd bloc-examples/go/stock
```

2. 看下我们这个项目有哪些“函数”
```shell
~/tmp/bloc-examples/go/stock $ cat main.go
package main

import (
	"bloc-examples/go/stock/bloc_node/new_stock"
	"bloc-examples/go/stock/bloc_node/phone_sms"
	"bloc-examples/go/stock/bloc_node/sleep"
	"bloc-examples/go/stock/bloc_node/stock_price_monitor"

	bloc "github.com/fBloc/bloc-client-go"
)

func main() {
	clientName := "stock_go"
	blocClient := bloc.NewClient(clientName)

	blocClient.GetConfigBuilder().SetRabbitConfig(
		"blocRabbit", "blocRabbitPasswd", []string{"127.0.0.1:5672"}, "",
	).SetServer(
		"127.0.0.1", 8080,
	).BuildUp()

	stockFunctionGroup := blocClient.RegisterFunctionGroup("Stock Monitor")
	stockFunctionGroup.AddFunction("NewStockMonitor", "new stock monitor", &new_stock.NewStock{})
	stockFunctionGroup.AddFunction("PriceMonitor", "stock real time monitor", &stock_price_monitor.StockPriceMonitor{})

	NoticeFunctionGroup := blocClient.RegisterFunctionGroup("Notice")
	NoticeFunctionGroup.AddFunction("Sms", "phone short message notice", &phone_sms.SMS{})

	ToolFunctionGroup := blocClient.RegisterFunctionGroup("Tool")
	ToolFunctionGroup.AddFunction("Sleep", "do sleep between nodes", &sleep.Sleep{})

	blocClient.Run()
}
```
可见，在`Stock Monitor`分组下有函数`NewStockMonitor`和`PriceMonitor`, `Notice`分组下有函数`Sms`, `Tool`分组下有函数`Sleep`

3. 将项目运行起来
前提：你已经安装了go语言环境
```shell
~/tmp/bloc-examples/go/stock $ go run main.go

```
不报错就表示没问题了。这时候请跳到最后看「基础功能演示」吧

## Python语言示例
这里我们将模拟一个在股票公司工作的开发者，其需要为股票经理开发一些功能。（注：此python实现的函数功能完全与上面Go语言示例的一致）

1. Clone [项目](https://github.com/fBloc/bloc-examples)到本地 并 进入相应目录
```shell
~/tmp $ git clone https://github.com/fBloc/bloc-examples.git && cd bloc-examples/python/stock
```

2. 看下我们这个项目有哪些“函数”
```shell
~/tmp/bloc-examples/python/stock $ cat main.py
import asyncio

from bloc_client import BlocClient

from bloc_node.sleep import SleepNode
from bloc_node.phone_sms import SMSNode
from bloc_node.new_stock import NewStockNode
from bloc_node.stock_price_monitor import StockPriceMonitorNode

async def main():
    client_name = "stock_py"
    bloc_client = BlocClient(name=client_name)

    bloc_client.get_config_builder(
    ).set_server(
		"127.0.0.1", 8080,
    ).set_rabbitMQ(
        user="blocRabbit", password='blocRabbitPasswd',
        host="127.0.0.1", port=5672
    ).build_up()

    stock_function_group = bloc_client.register_function_group("Stock Monitor")
    stock_function_group.add_function("PriceMonitor", "stock absolute price change monitor", StockPriceMonitorNode())
    stock_function_group.add_function("NewStockMonitor", "certain exchange & industry new stock monitor", NewStockNode())

    notice_function_group = bloc_client.register_function_group("Notify")
    notice_function_group.add_function("Sms", "phone short message notice", SMSNode())

    tool_function_group = bloc_client.register_function_group("Tool")
    tool_function_group.add_function("Sleep", "do sleep between nodes", SleepNode())

    await bloc_client.run()


if __name__ == "__main__":
    asyncio.run(main())
```
可见，在`Stock Monitor`分组下有函数`NewStockMonitor`和`PriceMonitor`, `Notice`分组下有函数`Sms`, `Tool`分组下有函数`Sleep`

3. 安装项目依赖库
建议python版本为3.8及以上。由于每个人管理依赖的姿势可能不太一样，提供了以下文件作为支持：
- 提供了最常用的`requirements.txt`文件，请以你舒服的姿势创建一个`virtualenv`并且安装依赖
- 如果你也使用`poetry`的话，可基于`pyproject.toml`和`pyproject.toml`安装依赖

4. 将项目运行起来
```shell
~/tmp/bloc-examples/python/stock $ python main.py 

```
不报错就表示没问题了。这时候请跳到最后看「基础功能演示」吧

# 基础功能演示
通过上面的步骤部署并运行了Python/Go示例项目（两个项目实现的函数功能完全一样）后，这时候我们来到前端ui看一下情况。

> 注意：如果跳转到登录页面，默认的用户名: `bloc`, 密码: `maytheforcebewithyou`

在浏览器打开[地址](http://localhost:8083/functions), 可看到步骤2里面的函数都显示在这里了, 如下图：
![functions](/static/functions.png)
可以看到、上面的函数一一对应了`main.go`里面的函数。

其中点击每个函数都能够看到对应函数的介绍以及输入输出的介绍。比如点击`PriceMonitor`这个函数：
![price_monitor_desc](/static/price_monitor_desc.png)

下一步可以试试自定义创建一个工作流, 通过在[这里](http://localhost:8083/flow)点击 + 可进入创建:
![create_flow](/static/create_flow.png)
上面通过将左边的函数拖拽到右边、以DAG的形式创建了一个监控tsla股票数据的工作流，分别监控了其price上下限，并在满足条件是通过`Sms`节点发送短信通知关注者。上面特别指出了对于函数输入参数值的指定方式：即可以是用户输入的写死的值、也可以是通过连线直接使用某个上游节点的某个输出数据值。

最后再说明下工作流的运行，如介绍所说，flow支持在前端直接被触发执行、crontab表达式调度、webhook触发执行。
![flow_list](/static/flow_list.png)

配置flow运行相关参数：
![flow_run_control](/static/flow_run_control.png)

查看运行历史：
![flow_run_history](/static/flow_run_history.png)

查看某次运行的详细数据：
![run_record_detail](/static/run_record_detail.png)

好啦，就列举这几个吧，别的功能请自己愉快的探索吧^_^
