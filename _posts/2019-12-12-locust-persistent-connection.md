---
layout: post
title:  "使用蝗虫(LOCUST)来进行百万长连接性能测试"
date:   2019-12-12 12:12:12
categories: locust persistent
---
最近公司在做一个IoT项目，需要把分布在全国的电池设备连接上中央服务器并上报数据。服务器端使用java+netty来进行开发，测试这块是个麻烦事了。之前团都是使用jmeter来进行压力测试，但jmeter这种基于线程方式的测试工具很难在单机上模拟出较高的并发数，开搜索引擎看一下最后我们选择了使用Locust来进行压测。Locust基于gevent使用协程机制，避免了系统资源调度，由此可以大幅度提高单机的并发性能。

## 安装
Locust是使用python开发的，需要先安装好python环境2.7、3.5、3.6、3.7、3.8都可以很好的支持。因操作系统的差距请自己前往(python官网)[https://www.python.org/downloads/]进行下载，