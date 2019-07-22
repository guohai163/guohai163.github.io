---
layout: post
title:  "快速组建程序集成环境"
date:   2019-07-19 22:59:06
categories: idea github jenkins debian CI
---
2014时在这里就写过一篇关于持续集成的文章[Jenkins 使用教程](/java/jenkins/2014/11/14/jenkins-use-tutorial.html)当时的Jenkins还是1.x版本，没想到5年过去了都9102年了，今天和朋友聊天还有团队在使用开发人员机器构建项目，人工ftp传到服务器上人工部署，累吗？也不安全啊。

最近在做一个小的项目使用SpringBoot框架搭建开发真的简单，但人工部署了三次服务器就觉得麻烦了，就在家里的树莓派上装了个Jenkins帮我来做自动部署，虽然派的CPU弱了点但毕竟省电。现在的整体框架环境是IDEA负责开发提交代码，github只是一个仓库负责存储代码，在有PUSH提交时触发Jenkins开始做构建动作。构建完成后按分支名字【develop分支上测试服，master分支上正式服】上不同的服务。并重启spring jar包。完成整个部署过程。

![flow](http://blog.guohai.org/doc-pic/2019-07/flow_chart.png)

## 创建Spring Boot项目，并生成Jenkinsfile文件