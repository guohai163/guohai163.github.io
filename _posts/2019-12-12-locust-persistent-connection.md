---
layout: post
title:  "使用蝗虫(LOCUST)来进行百万长连接性能测试"
date:   2019-12-12 12:12:12
categories: [network, performance-testing]
tags: [network, locust, persistent]
---
最近公司在做一个IoT项目，需要把分布在全国的电池设备连接上中央服务器并上报数据。服务器端使用java+netty来进行开发，测试这块是个麻烦事了。之前团都是使用jmeter来进行压力测试，但jmeter这种基于线程方式的测试工具很难在单机上模拟出较高的并发数，开搜索引擎看一下最后我们选择了使用Locust来进行压测。Locust基于gevent使用协程机制，避免了系统资源调度，由此可以大幅度提高单机的并发性能。

## 安装
Locust是使用python开发的，需要先安装好python环境2.7、3.5、3.6、3.7、3.8都可以很好的支持。因操作系统的差距请自己前往(python官网)[https://www.python.org/downloads/]进行下载，

1. 安装pip
~~~ shell
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
~~~

2. 安装locust
~~~ shell
pip install locustio
# 如果是windows可能还需要安装gevent.whl,请去往 https://www.lfd.uci.edu/~gohlke/pythonlibs/#gevent 下载 相对应 版本

pip install gevent‑1.4.0‑cp27‑cp27m‑win_amd64.whl
~~~

>    如果进行真实性能测试请不要使用windows平台，在windows下gevent的性能会有问题。使用类linux平台时请一定要修改最大文件打开数量。 可以使用ulimit -n查看当前支持的文件句柄，并用ulimit -n xxxx来进行修改

## 快速开始

~~~ python
# locust_test1.py
from locust import HttpLocust, TaskSet, task, between

class UserBehavior(TaskSet):
    def on_start(self):
        # on_start是在task中任何用户开始时都会调用的部分我们一般来进行初始化
        self.login()

    def on_stop(self):
        # on_stop 在停止时调用，我们可以用来回收资源
        self.logout()

    def login(self):
        self.client.post("/login", {"username":"ellen_key", "password":"education"})

    def logout(self):
        self.client.post("/logout", {"username":"ellen_key", "password":"education"})

    # @task装饰器，更方便我们的使用，所有带@task都会进行调用
    @task(2)
    def index(self):
        # 2/3的概率调用获得首页方法
        self.client.get("/")

    @task(1)
    def profile(self):
        # 1/3概率调用获得用户信息方法
        self.client.get("/profile")

class WebsiteUser(HttpLocust):
    host = "http://test.cn"
    # 我们首先给task_set赋值
    task_set = UserBehavior
    # 设定下次调用等待时间，单位为秒
    wait_time = between(5, 9)
~~~


接下来我们开始启动测试，可以使用`` locust -f locust_test1.py``来进行最简单化启动，之后可以去WEB界面 http://127.0.0.1:8089进行控制，也可以启用无WEB界面的方案 ``locust -f locust_test1.py --no-web -c 100 -r 20 -t 20m``该启动方案的含义是不使用web界面，模拟100用户，按20来进行递增，请求20分钟。

### 主从模式启动
~~~ shell
locust -f locst_test1.py --master
locust -f locst_test1.py --slave --master-host=192.168.110.19
~~~

## 长连接脚本

简单的安装和QG我们都看过了，现在我们开始实战tcp长连接方式。因内部通信协议保密我们使用之前我开源的一个[《超快地球物理坐标计算服务器》](https://github.com/guohai163/earth-server)来进行演示。首先我们使用docker来启动服务器 ``docker run --rm -t -p 40000:40000 gcontainer/earth-server earth_server -c``


我们首先创建一个Socket连接的基础类，主要负责socket连接的建立、收发消息、关闭
~~~ python
class SocketClient(object):

    def __init__(self):
        # 仅在新建实例的时候创建socket.
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def __getattr__(self, name):
        conn = self._socket
        def wrapper(*args, **kwargs):
            # 根据后面做的业务类，不同的方法做不同的处理
            if name == "connect":
                try:
                    conn.connect(args[0])
                except Exception as e:
                    print(e)
            elif name == "send":
                print(' '.join(hex(ord(i)) for i in args[0]))
                conn.sendall(args[0])
                data = conn.recv(1024)
                print(data)
            elif name == "close":
                conn.close()
        return wrapper
~~~

接下来我们创建一个实际的业务处理类UserBehavior集成自TaskSet
~~~ python
class UserBehavior(TaskSet):
    def on_start(self):
        # 该方法每用户启动时调用进行连接打开
        self.client.connect((self.locust.host, self.locust.port))
    def on_stop(self):
        # 该方法当程序结束时每用户进行调用，关闭连接
        self.client.close()

    @task(1)
    def sendAddCmd(self):
        # 处理坐标的增加1%的概率调用 该方法
        lat, log = generate_random_gps()
        dataBody = [
            'add ',
            ranstr(6),
            ' ',
            format(log,'f'),
            ' ',
            format(lat,'f'),
            '\x0d','\x0a']
        start_time = time.time()
        # 接下来做实际的网络调用，并通过request_failure和request_success方法分别统计成功和失败的次数以及所消耗的时间
        try:
            self.client.send("".join(dataBody))
        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            events.request_failure.fire(request_type="earthtest", name="add", response_time=total_time, response_length=0, exception=e)
        else:
            total_time = int((time.time() - start_time) * 1000)
            events.request_success.fire(request_type="earthtest", name="add", response_time=total_time, response_length=0)
    @task(99)
    def sendGetCmd(self):
        lat, log = generate_random_gps()
        dataBody = [
            'get ',
            format(log,'f'),
            ' ',
            format(lat,'f'),
            ' 5',
            '\x0d','\x0a']
        start_time = time.time()
        try:
            self.client.send("".join(dataBody))
        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            events.request_failure.fire(request_type="earthtest", name="get", response_time=total_time, response_length=0, exception=e)
        else:
            total_time = int((time.time() - start_time) * 1000)
            events.request_success.fire(request_type="earthtest", name="get", response_time=total_time, response_length=0)
~~~

最终实现我们的启动类，一个完整的调用过程结束

~~~ python
class SocketUser(SocketLocust):
    # 目标地址
    host = "127.0.0.1"
    # 目标端口
    port = 40000
    task_set = UserBehavior
    wait_time = between(0.1, 1)
~~~

我们模拟200用户启动下试试脚本。``locust -f locust_tcptest.py --no-web -c 200 -r 50 -t 10m``

![simulation 200 user](http://blog.guohai.org/doc-pic/2019-12/Locust-1.png)

## 参考资料

* [完整代码](https://github.com/guohai163/earth-server/blob/master/tools/locustscript.py)
* [超快地球物理坐标服务器](https://github.com/guohai163/earth-server)
* [Locust官网文档](https://docs.locust.io/en/stable/)
* [Python2教程](https://docs.python.org/2/tutorial/index.html)
