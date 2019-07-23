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

​```pipelines
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
​```

## 设置下github仓库


## Jenkins的配置