---
layout: post
title:  "SpringBoot项目在K8s环境下使用configmap"
date:   2022-03-15 10:10:00
categories: [develop]
tags: [k8s, java]
image: /doc-pic/2022/sb-love-k8s.png
---
SpringBoot和Kubernetes天生的组合。今天我们让他们组合的更深入一些，让SpringBoot项目使用K8S的Configmap和Secret。

## 开发环境准备
开发k8s应用首先我们应该把我们的机器加入到k8s的环境中，推荐工具KtConnect[注1]。KtConnect的工作原理就是创造了一个从本机到K8S集群中的VPN环境，让本机可以直接访问集群里的服务和域名。

先先官网按自己的操作系统和CPU平台下载对应的二进制文件，并放放本机的path路径下。mac/linux推荐直接放在 /usr/local/bin/ 下，windows推荐放在c:/tools/下并增加相应的环境变量。

安装好后使用 ktctl -v进行测试

~~~ shell
$ ktctl -v
KtConnect version 0.3.1
~~~

接下来要连接进k8S集群还要把集群内的k8s的config文件放入本机的 ~/.kube/下。请联系您的系统管理员申请该文件

接下我们尝试进行连接 

~~~ shell
# windows环境直接连接即可
> ktctl connect
00:00AM INF KtConnect start at <PID>
... ...
00:00AM INF ---------------------------------------------------------------
00:00AM INF  All looks good, now you can access to resources in the kubernetes cluster
00:00AM INF ---------------------------------------------------------------

# mac环境下需要使用root权限
$ sudo ktctl connect
00:00AM INF KtConnect start at <PID>
... ...
00:00AM INF ---------------------------------------------------------------
00:00AM INF  All looks good, now you can access to resources in the kubernetes cluster
00:00AM INF ---------------------------------------------------------------
~~~

## 项目搭建

## 本地测试

## 服务器测试

## 备注

* [KtConnect](https://alibaba.github.io/kt-connect/#/)