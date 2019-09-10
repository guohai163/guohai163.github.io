---
layout: post
title:  "Nexus Repository私服挂了后怎么办？"
date:   2019-09-09 22:59:59
categories: spring aliyun oss
---

团队内一直使用Nexus Repository搭建的私服为大家做包下载的加速，以及团队内自己的包管理。上个周末因为机房停电服务异常关机，周一上班后再开机服务死活起不来了。查看日志发现报错`OStorageException: Cannot open local storage '/data1/sonatype-work/nexus3/db/accesslog' with mode=rw`第一反应是文档没有权限读写，或被其他进程占用，把权限加到777了也无效。也没有其他进程在占用。开G搜了下大多提示就是DB损坏了修复云云，试了几个修复方案都不行，使用控制台加载OrientDB也是报同样错误。然而又没有进行过备份.....只能告诉同事一个好消息一个坏消息：好消息是我们的Nexus升级到了最新版本，界面又漂亮了点。坏消息是旧的Nexus挂掉了。

## 恢复数据
代理加速的我们直接配置好就行，等着慢慢同步即可。私有包我们团队使用Nexus主要存jar/dll从nuget开始算已经存了快6年了。让团队成员手工一个一个传太恐怖了。