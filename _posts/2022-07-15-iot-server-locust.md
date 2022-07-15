---
layout: post
title:  "物联网的服务端设计(五)"
date:   2022-07-15 10:10:00
categories: [netty]
tags: [iot, java, netty]
image: /doc-pic/2022/iot.svg
---

## 连接数测试

三年前写过一篇关于[socket压测的文章](http://blog.guohai.org/network/performance-testing/2019/12/12/locust-persistent-connection.html)，当时Locust还是0.x版本。现在已经进化到2.x版本，发现之前的的压测脚本已经跑不起来了，得重构下脚本。

程序有三个主要类，其中：
1. SocketClient 是基础的socket连接类，使用gevent来实现。
2. UserBehavior 继承自 TaskSet 主要实现的用户的登录和心跳方法
3. SocketUser 是我们的启动类。主要进行tasks 标记。和压测间隔

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
                print(args[0])
                conn.sendall(args[0].encode())
                data = conn.recv(1024)
                print(data)
            elif name == "close":
                conn.close()

        return wrapper


class UserBehavior(TaskSet):
    def on_start(self):
        # 该方法每用户启动时调用进行连接打开
        self.client.connect((self.user.host, self.user.port))
        self.send_login()

    def on_stop(self):
        # 该方法当程序结束时每用户进行调用，关闭连接
        self.client.close()

    def send_login(self):
        start_time = time.time()

        tx_no = int(round(start_time * 1000))
        dataBody = '{"msgType": 10, "devId": "%s", "version":"1.0", "txNo": "%d", "sign": "xxxxx"}' % (
            uuid.uuid1(), tx_no)

        # 接下来做实际的网络调用，并通过request_failure和request_success方法分别统计成功和失败的次数以及所消耗的时间
        try:
            self.client.send(dataBody)
        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            events.request_failure.fire(request_type="iot_server", name="login", response_time=total_time,
                                        response_length=0, exception=e)
        else:
            total_time = int((time.time() - start_time) * 1000)
            events.request_success.fire(request_type="iot_server", name="login", response_time=total_time,
                                        response_length=0)

    @task(1)
    def send_20(self):
        start_time = time.time()

        tx_no = int(round(start_time * 1000))
        dataBody = ' {"msgType": 20, "txNo": "%d"}' % tx_no

        try:
            self.client.send(dataBody)
        except Exception as e:
            total_time = int((time.time() - start_time) * 1000)
            events.request_failure.fire(request_type="iot_server", name="msg_20", response_time=total_time,
                                        response_length=0, exception=e)
        else:
            total_time = int((time.time() - start_time) * 1000)
            events.request_success.fire(request_type="iot_server", name="msg_20", response_time=total_time,
                                        response_length=0)


class SocketLocust(User):
    abstract = True

    def __init__(self, *args, **kwargs):
        super(SocketLocust, self).__init__(*args, **kwargs)
        self.client = SocketClient()


class SocketUser(SocketLocust):
    # 目标地址
    host = "127.0.0.1"
    # 目标端口
    port = 4100
    tasks = [UserBehavior]
    wait_time = between(50, 70)

~~~

准备压测环境

1. 服务端使用docker模式运行，限制内存为1024M，java进程启动时限制栈大小为512M. ``docker run --rm -m 1024m -p 4100:4100 gcontainer/iot-server:1.0``
2. 启动我们的测试脚本 ``locust -f locustscript.py`` 最大连接数为10000，步进设置到20.

先看Locust的测试的结果:

![/doc-pic/2022/locust_10000.png](/doc-pic/2022/locust_10000.png)

服务器上达到10000连接后，CPU正常是没有压力的，内存可以看到老年代占用了24M为保持连接所占用的。整体内存占用了360M其中会包括原空间内bytebuf占用的部分

本节 [源码](https://github.com/guohai163/iot-server/tree/v0.4)