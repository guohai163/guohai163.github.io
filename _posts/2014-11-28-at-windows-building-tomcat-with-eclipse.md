---
layout: post
title:  "在WINDOWS系统下构建tomcat,并加载至eclipse中"
date:   2014-11-28 11:59:06
categories: tomcat source code eclipse
---

###下载Java Development Kit (JDK) 7###
可以使用oracle的jdk也可以使用openjdk或其它任意版本JDK都可以。但如果你要编译tomcat8最高只可以用jdk7否则可以会报错，同理你要编译tomcat7的源码必须使用jdk6否则也会报错。

下载完成后请一定要培训系统变量中的JAVA_HOME到你的JDK安装目录。

###安装Apache Ant 1.8.1或更高版本###
去官网下载二进制版本ANT，解压到硬盘中。并配置系统变更ANT_HOME到安装目录，同时修改PATH到${ant.home}/bin下方便执行

###获得TOMCAT8源码###
两种方法获取

1. 通过源码版本库获取，支持SVN和GIT【只读】
2. 通过直接下载源码包。

假设我们最后源码目录为${tomcat.source} 

###构建Tomcat###
使用如下命令即可构建tomcat

	cd ${tomcat.source}
	ant

*注意*：运行以上命令将会下载一些类库到默认的/usr/share/java下，因为本教程为WINDOWS版本，所以请修改`${tomcat.source}/build.properties`文件内`base.path`属性值为`base.path=C:/path/to/the/repository`

看到提示`BUILD SUCCESSFUL`成功，去你的`${tomcat.source}/output/build`目录应该已经可以看到生成成功的二进制版本。

###导入Eclipse### 
首先使用ant命令去重新生成

	cd ${tomcat.source}
	ant ide-eclipse

*注意*：如果你和我一样不幸生活在墙后，其中有几个包会下载失败。请VPN后再执行`ant ide-eclipse`

1. 打开Eclipse创建一个新的工作区
2. 修改Eclipse类变量` Java->Build Path->Classpath Variables`增加两个类变量`TOMCAT_LIBS_BASE`,`ANT_HOME`
3. 导入项目`File->Import and choose Existing Projects into Workspace.`

###参考资料###
* [Oracle JDK](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
* [Open JDK](http://openjdk.java.net/install/index.html)
* [Apache ant](http://ant.apache.org/bindownload.cgi)
* [Tomcat8](http://tomcat.apache.org/download-80.cgi)