---
layout: post
title: "使用Jenkins自动构建iOS项目"
date: 2017-03-24 14:00
categories: xcode oc ci
---

### 目的 ###



### 需要软件 ###

1. macOS系统，apple开发都帐号
2. 安装Xcode最新版本，可以通过 https://developer.apple.com/download/more/ 下载离线版本
3. 安装[JDK for macOS](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)版本，如果只生成iOS项目在同一机器不需要生成android可以只安装jre.
4. 最重要的jenkins的pkg版本。https://jenkins.io/content/thank-you-downloading-os-x-installer#stable

### 安装 ###

* #### 安装JDK ####

按提示下一步，下一步即可
![jdk install](http://guohai163.github.io/doc-pic/jenkins4xcode/jdk-install.png)

* #### 安装Jenkins ####

下载好pkg文件后双击即可，安装后jenkins会自动安装为Daemon模式，并会创建 jenkins用户以及jenkins用户组，并创建 /Users/Shared/Jenkins 目录。
![jenkins install](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-install.png)

更多配置在 /Library/Preferences/org.jenkins-ci.plist 文件里

~~~
//查看配置请运行
defaults read /Library/Preferences/org.jenkins-ci
//查看某个值的配置
defaults read /Library/Preferences/org.jenkins-ci SETTING
//修改值
defualts write /Library/Preferences/org.jenkins-ci SETTING VALUE
~~~

启动或停止服务

```
//start daemon
sudo launchctl load /Library/LaunchDaemons/org.jenkins-ci.plist
//stop daemon
sudo launchctl unload /Library/LaunchDaemons/org.jenkins-ci.plist
```

卸载 Jenkins for macOS
```
/Library/Application Support/Jenkins/Uninstall.command
```

#### 初始化Jenkins ####

请使用浏览器打开 [http://localhost:8080](http://localhost:8080)

* 解锁Jenkins，请密码在本地文件中 ``` sudo cat /Users/Shared/Jenkins/Home/secrets/initialAdminPassword ```
![jenkins init 1](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-init-1.png)

* 安装插件，直接默认使用推荐插件即可，但Jenkins在国内访问会比较慢，插件可能要安装很久
![jenkins init 1](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-init-2.png)
![jenkins init 1](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-init-3.png)
