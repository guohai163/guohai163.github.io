---
layout: post
title:  "Jenkins 使用教程"
date:   2014-11-14 21:59:06
categories: [continuous-integration 4]
tags: [java, jenkins]
---

### Ubuntu上安装Oracle Java SDK ###

1. 下载用于Ubuntu的Oracle JAVA JDK 选择正确的版本，记得做一次MD5效验。
2. 解压安装  
	`tar -zxvf jdk-8u11-linux-i586.tar.gz`
3. 拷贝到指定目录  
	`sudo mv jdk1.8.0_11 /usr/lib/`
4. 修改环境变量`vi ~/.bashrc` 添加  

		export JAVA_HOME=/usr/lib/jdk1.8.0_11  
		export JRE_HOME=${JAVA_HOME}/jre  
		export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib  
		export PATH=${JAVA_HOME}/bin:$PATH  

  保存退出，并输入`source ~/.bashrc`使该更改立即生效  
5. **配置默认JDK版本**  

		sudo update-alternatives --install /usr/bin/java java /usr/lib/jdk1.8.0_11/bin/java 300
		sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jdk1.8.0_11/bin/javac 300
		sudo update-alternatives --install /usr/bin/jar jar /usr/lib/jdk1.8.0_11/bin/jar 300
		sudo update-alternatives --install /usr/bin/javah javah /usr/lib/jdk1.8.0_11/bin/javah 300
		sudo update-alternatives --install /usr/bin/javap javap /usr/lib/jdk1.8.0_11/bin/javap 300
执行代码 `sudo update-alternatives --config java`选择你要使用的JDK版本。  
6. 测试 `java -version`看看是否是Oracle版本的JDK

### Maven安装###

1. 下载
2. 解压缩并拷贝  
3.
		tar -axvf apache-maven-3.2.2-bin.tar.gz
		sudo mv apache-maven-3.2.2 /usr/local/
		sudo ln -s apache-maven-3.2.2 apache-maven

		export M2_HOME=/usr/local/apache-maven
		export M2=$M2_HOME/bin
		export PATH=$M2:$PATH

### Tomcat安装###

		sudo apt-get update
		sudo apt-get install tomcat7

### Jenkins安装###

1. 下载Jenkins
2. 启动Jenkins `cp jenkins.war /var/lib/tomcat7/webapps`
3. 找到合适的位置创建jenkins_home目录，并修改目录所有者为tomcat7

		sudo mkidr /home/tomcat7/jenkins_home
		sudo chown tomcat7:tomcat7 -R /home/tomcat7
3. 修改环境变量，打开`sudo vi /var/lib/tomcat7/webapps/jenkins/WEB-INF/web.xml`.修改env-entry-value节点为`jenkins_home`目录。
4. 创建`.m2`和`.jenkins`目录

		sudo mkdir /usr/share/tomcat7/.m2
		sudo chow tomcat7:tomcat7 /usr/share/tomcat7/.m2
		sudo mkdir /usr/share/tomcat7/.jenkins
		sudo chow tomcat7:tomcat7 /usr/share/tomcat7/.jenkins
4. 重启tomcat
3. 访问 http://jenking_host:8080/
4. 插件安装，`系统管理->管理插件->可选插件` 需要安装 `GIT plugin`、`GIT client plugin`、`Maven Project Plugin`三个插件
5. 配置插件 `系统管理->系统设置->`
	1. JDK
	![jdk-setup.png](http://guohai163.github.io/doc-pic/jenkins-tutorial/jdk-setup.png)
	2. Git
	![git-setup.png](http://guohai163.github.io/doc-pic/jenkins-tutorial/git-setup.png)
	3. Maven
	![maven-setup.png](http://guohai163.github.io/doc-pic/jenkins-tutorial/maven-setup.png)

### 创建首个Job###
本教程本次以Maven项目为例子 `首页->新建`  
![create-job-step-1.png](http://guohai163.github.io/doc-pic/jenkins-tutorial/create-job-step-1.png)
源代码管理，我们使用GIT，只要写入远程仓库的URL*本次测试使用SSH公私钥验证*。`Branches to build`后写入你想生成的分支
![source-code-manage.png](http://guohai163.github.io/doc-pic/jenkins-tutorial/source-code-manage.png)
修改构建配置
![build-manage.png](http://guohai163.github.io/doc-pic/jenkins-tutorial/build-manage.png)
