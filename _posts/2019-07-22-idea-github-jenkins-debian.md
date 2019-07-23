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

想让社区版使用向导创建Spring项目就需要先安装“Spring Assistant”这个插件，之后就可以使用File->Project->Spring Assistant->Next->给项目起个名字,选择下项目类型和项目要使用的语言->Next->勾选下你要依赖的组件比如Spring Boot->Next->确定下项目的目录->Finish。一个最简单的SB项目创建好了。

为了配合Jenkins做构建，我们还要在项目中加点料。目前Jenkins主推是使用Pipelines来定义构建中的每一步，Pipelines又分为声明式和脚本化。相比脚本化的流水线语法，声明式提供更丰富的语法特性。声明式需要在项目的根目前创建一个 `Jenkinsfile`文件，来存放构建的脚本。具体的语法可以参考官方文档 [流水线语法](https://jenkins.io/zh/doc/book/pipeline/syntax/) 我们直接用一个成品脚本来讲解。

``` java
pipeline {
  agent any
  environment {
    //目标服务器IP以及登陆名
    TAG_SERVER = 'guohai@guohai.org'
    //目标服务器程序部署路径
    TAG_PATH = '/data/vaccine.guohai.org'
    //目标服务器启动停止springboot脚本路径
    TAG_SCRIPT = '/data/spring-boot.sh'
  }

  stages {
    //构建块
    stage ('build') {
      steps {
         script{
            //获得maven程序路径
            def mvnHome = tool 'maven 3.6.0'
            //打包
            sh "${mvnHome}/bin/mvn clean package"
            echo "build over"
         }

      }
    }
    //联署块
    stage ('deploy') {
        steps {
            //计算本地文件MD5
            sh "md5sum ${WORKSPACE}/target/*.jar"
            //因为我们要使用私钥来操作远程服务器内容，下面的代码块需要使用withCredentials括起来，其中credentialsId为在Jenkins里配置的证书。keyFileVariable为代码块中可以使用的变量名
            withCredentials([sshUserPrivateKey(credentialsId: 'guohai.org', keyFileVariable: 'guohai_org_key', passphraseVariable: '', usernameVariable: '')]) {
                //拷贝本地JAR文件到服务器上
                sh "scp -i ${guohai_org_key} ${WORKSPACE}/target/*.jar ${TAG_SERVER}:${TAG_PATH}/${JOB_BASE_NAME}.jar"
                //计算拷贝到服务器上的文件 MD5，确保与本地一致。避免因传输产生的错误。
                sh "ssh -i ${guohai_org_key} ${TAG_SERVER} md5sum ${TAG_PATH}/${JOB_BASE_NAME}.jar"
                //使用脚本重启spring boot
                sh "ssh -i ${guohai_org_key} ${TAG_SERVER} ${TAG_SCRIPT} restart ${TAG_PATH}/${JOB_BASE_NAME}.jar"
            }

        }
    }
  }
}
```


## 设置下github仓库

仓库这块设置就比较简单了，去github创建一个空仓库。将本地代码push上来，然后去配置下webhooks。Payload URL里配置上你的Jenkins的通知地址。图片中遮挡部位是jenkins的IP或域名。默认是push事件会触发这个规则。你可以修改为自定义其它事件。
 ![webhook](http://blog.guohai.org/doc-pic/2019-07/github-webhook.png)

## Jenkins的配置

如果你不需要在一台机器上跑多分Jenkins建议还是尽量用包的方式来安装。比用war包形式省事很多，因我的派上装的是debian系统，这里我就用Debian/Ubuntu来举例。

``` shell
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
```
安装完后会默认监听8080口，[这里有坑]但上一步的github回调在8080口上一直没有成功。派上的80口已经被nginx占用了，这里就不用修改jenkins的端口了，直接在nginx上配置一下反向代理即可。安装过程一路下一步就行，插件看你的情况适量安装。

1. 配置Jenkins的Maven：maven可以手工安装，然后给jenkins配置环境变量就行，这里想偷懒直接让jenkins帮我下载安装。选择 系统管理->全局工具配置，在Maven分类下点击Maven安装勾选自动安装选择一个比较新的版本号。在Name标签中填写一个名字。这个名字要和Jenkinsfile里的一致。
 ![j-maven](http://blog.guohai.org/doc-pic/2019-07/j-maven.png)
2. 配置连接远程服务器私钥：SSH服务器的连接建议尽量全用私钥的形式，不要使用用户名+密码不安全。在Jenkins里点击凭据->添加凭据。类型选择[SSH Username with private key],ID起一个唯一好记的名字就行，比如服务器IP或域名。用户名为远程主机用户名。在PrivateKey里选择Enter directly点击Add后选择你的私钥文件即可
![j-credentials](http://blog.guohai.org/doc-pic/2019-07/j-credentials.png)
3. 都配置完了我们来创建构建任务：名字，按你的项目起就行，类型选择流水线/Pipelines。在构建触发器要勾选下 [GitHub hook trigger for GITScm polling]这样上一步的提交钩子就能触发本地构建了。
4. 将流水线内的定义切成 [Pipeline script from SCM] 配置好你的仓库地址和分支名字，脚本路径如果上次无变化保持默认即可。
![j-pipeline](http://blog.guohai.org/doc-pic/2019-07/j-pipeline.png)

Jenkins的部分到此结束。

## 线上服务器的配置

线上只要配置好权限，放一个[脚本](http://blog.guohai.org/doc-pic/2019-07/spring-boot.sh)上去即可，脚本的功能是帮你重启jar包的。路径要和第一步里的Jenkinsfile里配置的一致。

## 结束语

至此整个过程1个小时左右，就全部搞定了。奉劝各位团队们不要在手工部署了太不安全了。
