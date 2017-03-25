---
layout: post
title: "使用Jenkins自动构建iOS项目"
date: 2017-03-24 14:00
categories: xcode oc ci
---

### 目的 ###
大多APP开发团队都会存在这样一问题，开发人员直接在自己机器上给测试人员安装APP程序。整个代码不会经过源码服务器，甚至开发人员机器硬盘损坏或离职后产生严重后果。为了避免产生这样的问题，我们可以考虑使用CI系统，保证所有二进制包都是经过源码服务器，测试人员直接可以进行测试。


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
![jenkins init 2](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-init-2.png)
![jenkins init 3](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-init-3.png)

* 设置管理员用户名密码。初始化结束
![jenkins init 4](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-init-4.png)

#### 创建你的首个xcode build item ####
* 构建xcode项目需要安装的插件
   * Xcode integration
   * 源码拉取相关插件这里我们使用 Git Plugs
* 新建一个自由风格的软件项目，给他起一个名字
![jenkins create item 1](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-create-item-1.png)
* General标签，建议勾选丢弃旧的构建，防止占用过多磁盘空间
![jenkins create itme 2](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-create-item-2.png)
* 源码管理标签，选择适合你的标签页面，这里我们使用Git源。构建触发器，可以选择在适当的时候触发，比如我们的master分支就会在每天凌晨构建一次，保证第二天QA来上班有一个可测的版本。开发分支可以和GitLab互动，有push就触发一次构建。
* 重点：构建标签，点击“增加构建步骤”选择Xcode.
    * 使用自动构建对于你的Xcode项目有一些要求
        1. 项目必须有xworkspace文件
        2. 项目必须有Scheme文件

* General build settings![jenkins create itme 3](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-create-item-3.png)

    1. Target请写入项目中对应的名字即可
    2. Clean before build建议勾选
    3. 因为想通过WEB直接安装请勾选 Pack application and build .ipa?
    4. ipa名字，直接直接输入一个就行可以利用环境变量，用不接.ipa
    5. 输出目录我们输出到工作区的build下，${WORKSPACE}/build/

* Code signing & OS X keychain options![jenkins create itme 4](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-create-item-4.png)
    0. 先打开Xcode的Preferences,添加好带开发者证书的AppleID,以及下载好相对应的mobileprovision文件。
    1. 拷贝当前用户下的login.keychain 和 login.keychain-db文件到Jenkins用户下 ``` sudo cp /Users/${username}/Library/Keychains/login.keychain* /Users/Shared/Jenkins/Library/Keychains/ ```
    2. 拷贝当前用户下的mobileprovision文件到Jenkins用户下 ```sudo cp Provisioning\ Profiles/* /Users/Shared/Jenkins/Library/MobileDevice/Provisioning\ Profiles/```
    3. 勾选Unlock Keychain否则无法使用保存的证书。Keychain Path填写默认值即可 ```${HOME}/Library/Keychains/login.keychain``` Keychain password 填写当前用户密码
* Advanced Xcode build options![jenkins create itme 5](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-create-item-5.png)
    1. 所有空按你的项目适当填写即可。
* 保存构建，等待成功。![jenkins create itme over](http://guohai163.github.io/doc-pic/jenkins4xcode/jenkins-create-item-over.png)

### 让QA可以直接从手机上安装应用 ###
目前我们的测试人员已经可以通过Jenkins网站下载ipa后通过iTunes来安装我们的APP了，但还是比较麻烦，下一步我们要做的就是搭建一个APP下载站点让QA可以直接通过手机自动安装应用。必要条件：你的WEB站点必须是一个HTTPS的站点，iOS7以后系统才可以直接安装

1. 创建manifest.plist文件

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="ver 2013.01.09 1.01.02(.02)">
  <dict>
    <key>items</key>
    <array>
      <dict>
        <key>assets</key>
        <array>
          <dict>
            <key>kind</key>
            <string>software-package</string>
            <key>url</key>
            <string>[ipa文件URL地址]</string>
          </dict>
          <dict>
            <key>kind</key>
            <string>full-size-image</string>
            <key>needs-shine</key>
            <false/>
            <key>url</key>
            <string>[Icon地址]</string>
          </dict>
          <dict>
            <key>kind</key>
            <string>display-image</string>
            <key>needs-shine</key>
            <false/>
            <key>url</key>
            <string>[Icon地址]</string>
          </dict>
        </array>
        <key>metadata</key>
        <dict>
          <key>bundle-identifier</key>
          <string>[应用的bundleid]</string>
          <key>bundle-version</key>
          <string>[版本号]</string>
          <key>kind</key>
          <string>software</string>
          <key>subtitle</key>
          <string></string>
          <key>title</key>
          <string>[应用名]</string>
        </dict>
      </dict>
    </array>
  </dict>
</plist>
```
2. 创建一个HTML文件

``` html
<a href="itms-services://?action=download-manifest&url=https://guohai.org/manifest.plist">点击安装location</a>
```
