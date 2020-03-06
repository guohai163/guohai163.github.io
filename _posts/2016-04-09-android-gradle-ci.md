---
layout: post
title: Gradle架构Adnroid项目使用Jenkins的持续集成方法
author: guohai
tags: gradle android jenkins git
categories: [continuous-integration]
tags: [gradle, android, jenkins, git]
---

## 1.基础环境的搭建和准备 ##
首先准备的Jenkins本身的安装，之前的教程已经讲解过[安装方法](http://guohai163.github.io/java/jenkins/2014/11/14/jenkins-use-tutorial.html)。

还要事先在服务器上准备好[android-sdk](http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz).

下载解压后的sdk还是无法使用的，缺少buildtools等工具,可以通过update sdk参数来安装。

```shell
tar -zxvf android-sdk_r24.4.1-linux.tgz
cd android-sdk-linux
tools/android update sdk -u
#之后 blablaba会让你授权一大堆协议，开始安装。但这个命令只会安装最新版本的build tools。比如我现在默认安装的就是24预览版。如果你的网络足够好可以通过
tools/android update sdk -a -u
#命令来安装所有版本的构建工具或者通过list sdk可看列表后使用-t进行过滤安装
tools/android list sdk -a
Packages available for installation or update: 149
   1- Android SDK Tools, revision 25.1.1
   2- Android SDK Platform-tools, revision 23.1
   3- Android SDK Platform-tools, revision 24 rc1
   4- Android SDK Build-tools, revision 24 rc2
   5- Android SDK Build-tools, revision 23.0.3
   6- Android SDK Build-tools, revision 23.0.2
   7- Android SDK Build-tools, revision 23.0.1
   8- Android SDK Build-tools, revision 23 (Obsolete)
   9- Android SDK Build-tools, revision 22.0.1
  10- Android SDK Build-tools, revision 22 (Obsolete)
  11- Android SDK Build-tools, revision 21.1.2
  12- Android SDK Build-tools, revision 21.1.1 (Obsolete)
  13- Android SDK Build-tools, revision 21.1 (Obsolete)
  14- Android SDK Build-tools, revision 21.0.2 (Obsolete)
  15- Android SDK Build-tools, revision 21.0.1 (Obsolete)
  16- Android SDK Build-tools, revision 21 (Obsolete)
  17- Android SDK Build-tools, revision 20
  ...................
#比如我想只安装23.0.3版的build tools只要输入
tools/android update sdk -a -t 5 -u
```
当然对于在中国大陆的大多开发者来说，可能你连下载sdk的网址都打不开。我这里打包了一个有大多Build-tools版本的SDK放到的百度云[android-sdk-linux](http://pan.baidu.com/s/1nvvQihj)密码[ccl2]

最后还要记得在服务器的环境变量中增加ANDROID_HOME

## 2.Jenkins的配置

* 现在Android Studio IDE已经被Google进行主推，而默认的程序框架也是Gradle风格，所以请先在Jenkins中下载Gradle插件如果网络不好可以先下载然后在Jenkins中手动安装。
* 配置Gradle安装路径，从网上下载Gradle并解压在服务器上，打开Jenkisn的 Manage Jenkins->Configure System->Gradle->Add Gradle

   ![image](http://guohai163.github.io/doc-pic/2016-04-09/gradle-setup.png)
* 接下来新建一个构建项目，并选择构建一个自由风格的软件项目
* 在源码管理中选择合适的源码管理系统和地址分支
* 增加构建步骤Invoke Gradle script

   ![image](http://guohai163.github.io/doc-pic/2016-04-09/invoke-gradle-script.png)

* 默认构建完apk文件无法在WEB界面下载，我们还要增加构建后操作。对APK进行存档

   ![image](http://guohai163.github.io/doc-pic/2016-04-09/archive-file.png)

* 保存配置项目，点击Build Now按钮即可等待APK下载

   ![image](http://guohai163.github.io/doc-pic/2016-04-09/over.png)

## 3.后记
* Linux服务器有可能的话请使用32位版本，否则appt等工具全是32位的会提示缺少很多32位的动态链接库。比如找不到zlib.so.1.
* 请确保客户端所用的buildtools版本在服务器上也有。否则会报`failed to find Build Tools revision 23.0.3`
* 请一定配置环境变量ANDROID_HOME并指向SDK目录否则会报`ava.lang.RuntimeException: SDK location not found. Define location with sdk.dir in the local.properties file or with an ANDROID_HOME environment variable`
* 生成时可能通不过lint检查，可以先注掉。编辑app/build.gradle文件增加

    ```xml
    android {
         lintOptions {  
          abortOnError false  
      }  
    }
    ```
* 最后一条，做为一个Android开发随时准备从Google下载文件失败的准备
