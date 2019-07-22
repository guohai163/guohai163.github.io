---
layout: post
title:  "快速组建Java项目持续集成环境"
date:   2019-07-19 22:59:06
categories: idea github jenkins debian CI Java
---
2014年时在这里就写过一篇关于持续集成的文章[Jenkins 使用教程](/java/jenkins/2014/11/14/jenkins-use-tutorial.html)当时的Jenkins还是1.x版本，没想到5年过去了都9102年了，今天和朋友聊天还有团队在使用开发人员机器构建项目，人工ftp传到服务器上人工部署，累吗？也不安全啊。

最近在做一个小的项目使用Spring Boot框架，搭建开发真的简单，但人工部署了三次服务器就觉得麻烦了，就在家里的树莓派上装了个Jenkins帮我来做自动部署，现在的Jenkins已经内置了一个Java servlet 容器/应用程序服务器，直接执行jar包即可，不用再像之前一样还需要装个Tomcat当servlet容器。不过我现在用的还是派3 CPU弱了点，一开始构建项目派的两个核心的CPU就跑满，磁盘IO性能也不行。等大家多点赞我以后也能换个派4耍耍😄😄。

现在的整体框架环境是IDEA负责开发提交代码，github只是一个仓库负责存储代码，在有PUSH提交时触发Jenkins开始做构建动作。构建完成后按分支名字【develop分支上测试服，master分支上正式服】上不同的服务。并重启spring jar包。完成整个部署过程。

![flow](http://blog.guohai.org/doc-pic/2019-07/flow_chart.png)

## 创建Spring Boot项目，并生成Jenkinsfile文件
Java项目的IDE目前得推荐下[IntelliJ IDEA](https://www.jetbrains.com/idea/)按官方的解释Ultimate主要适合做WEB和企业应用比如支持Spring，而Community比较适合JVM和Android开发。但因为Spring Boot的出现，现在社区版本对web的支持也不错，也可以断点调试。只是对于模板引擎支持真的比较惨。Java语言是主力开发的就花钱买Ultimate吧，玩一玩的用Community就够了。



## 设置下github仓库


## Jenkins的配置