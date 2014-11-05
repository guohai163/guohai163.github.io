---
layout: post
title:  "使用Sonatype Nexus搭建Maven私有仓库
date:   2014-11-04 21:59:06
categories: java maven
---

###私有仓库的优点###

1. 服务器在内网，下载速度快
2. 一个人使用过，其它再次使用不需要重复下载，减少对外流量
3. 发布团队自有私有类库

###安装Sonatype Nexus###
本次安装系统环境 `debian/ubuntu` 首先去官方网站 [http://www.sonatype.org/nexus/](http://www.sonatype.org/nexus/)可以看到Nexus有两种发放形式，war包

可以直接部署到tomcat下。tgz or zip可以直接执行的版本。我们首先看看tgz版本的安装方法。  

1. 下载 `wget http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz`  

2. 另外运行nexus需要有jre支持如果没有安装可以通过 `apt-get install default-jre` 来进行安装  *请确认你安装的jre版本是否大于1.7*
3. 将 nexus cp 到 `/usr/local/` 目录下再进行解压缩

		$ sudo cp nexus-2.8.0-05-bundle.tar.gz /usr/local
		$ cd /usr/local
		$ sudo tar xvzf nexus-2.8.0-05-bundle.tar.gz
		$ ln -s nexus-2.8.0-05 nexus

4. 运行Nexus,`/usr/local/nexus/bin/nexus console`。当启动成功可以看到如下提示

		Running Nexus OSS...
		wrapper  | --> Wrapper Started as Console
		wrapper  | Launching a JVM...
		jvm 1    | Wrapper (Version 3.2.3) http://wrapper.tanukisoftware.org
		jvm 1    |   Copyright 1999-2006 Tanuki Software, Inc.  All Rights Reserved.

5. 如果以上步骤没有报错即可，至浏览器访问[http://nexus.host:8081/nexus/](http://nexus.host:8081/nexus/)。

no zuo no die。采用这种方式安装的有个天生缺陷，对CPU的支持有限。查看bin/jsw目录会发现 `linux-ppc-64  linux-x86-32  linux-x86-64  macosx-universal-32  macosx-universal-64  solaris-sparc-32  solaris-sparc-64  solaris-x86-32  windows-x86-32  windows-x86-64` 如果我们的CPU在以上类型以外比如树霉派的ARM类型。那么你将要学习如下安装方法。使用WAR包安装

1. 安装tomcat7
2. 下载war包 `wget http://download.sonatype.com/nexus/oss/nexus-2.10.0-02.war`
3. 将war包拷贝到 `{TOMCAT_HOME}/webapps`,在目录 `/usr/share/tomcat7`下创建 `sonatype-work`目录，并将所有者修改为 tomcat7
4. 此时查看机器负载配置不高的单核机器很快就会跑到1.7，稍等片刻
5. 再次打开你的浏览器 [http://nexus.host:8080/nexus/](http://nexus.host:8080/nexus/)记得修改端口tomcat默认商品和刚刚的tgz目录可不一样。

![nexus-welcome-page.png](http://guohai163.github.io/doc-pic/nexus-tutorial/nexus-welcome-page.png)

###下载中央仓库包###

1. 点击左侧 `Repositories`,在列表中选择 Central 。打开Configuration标签，将Download Remote Indexes改为True即可开始自动下载。
2. 如果你不幸在中国大陆，连中央仓库下载索引会慢的要死。解决方案有二。
	1. 打开你仓库的配置节点，修改`HTTP Request Settings->Request Timeout`改的大点我基本都是3小时左右超时。
	2. 手工下载索引文件，然后按官方路径放置。修改你机器的HOSTS文件把repo1.maven.org域名指向你的假机器即可
	
###Maven私有库的使用###
1. 在你的`~/.m2/`目录下增加一个新文件`settings.xml`。文件内容为

		<settings>
		  <mirrors>
		    <mirror>
		      <!--This sends everything else to /public -->
		      <id>nexus</id>
		      <mirrorOf>*</mirrorOf>
		      <url>http://localhost:8080/nexus/content/groups/public</url>
		    </mirror>
		  </mirrors>
		  <profiles>
		    <profile>
		      <id>nexus</id>
		      <!--Enable snapshots for the built in central repo to direct -->
		      <!--all requests to nexus via the mirror -->
		      <repositories>
		        <repository>
		          <id>central</id>
		          <url>http://central</url>
		          <releases><enabled>true</enabled></releases>
		          <snapshots><enabled>true</enabled></snapshots>
		        </repository>
		      </repositories>
		     <pluginRepositories>
		        <pluginRepository>
		          <id>central</id>
		          <url>http://central</url>
		          <releases><enabled>true</enabled></releases>
		          <snapshots><enabled>true</enabled></snapshots>
		        </pluginRepository>
		      </pluginRepositories>
		    </profile>
		  </profiles>
		  <activeProfiles>
		    <!--make the profile active all the time -->
		    <activeProfile>nexus</activeProfile>
		  </activeProfiles>
		</settings>

2. 之后再使用Maven时就会在本地Nexus仓库进行下载。

###后续###

当然Nexus功能或要学习的东西还不止这些。比如怎么在Nexus上部署Nuget,让.Net程序可以来这下载包。怎么上传自己私有的JAR包，如果监控NEXUS状态。我会在今后的BLOG上继续更新。