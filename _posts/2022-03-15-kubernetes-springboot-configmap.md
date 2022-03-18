---
layout: post
title:  "SpringBoot项目在K8s环境下使用configmap"
date:   2022-03-15 10:10:00
categories: [develop]
tags: [k8s, java]
image: /doc-pic/2022/sb-love-k8s.png
---
SpringBoot和Kubernetes天生的组合。今天我们让他们组合的更深入一些，让SpringBoot项目使用K8S的Configmap和Secret。同时还会讲述下在本机环境下如何请求k8s内的其他服务。

## 开发环境准备
开发k8s应用首先我们应该把我们的机器加入到k8s的环境中，推荐工具KtConnect[注1]。KtConnect的工作原理就是创造了一个从本机到K8S集群中的VPN环境，让本机可以直接访问集群里的服务和域名。

先先官网按自己的操作系统和CPU平台下载对应的二进制文件，并放放本机的path路径下。mac/linux推荐直接放在 /usr/local/bin/ 下，windows推荐放在c:/tools/下并增加相应的环境变量。

安装好后使用 ktctl -v进行测试

~~~ shell
$ ktctl -v
KtConnect version 0.3.1
~~~

接下来要连接进k8S集群还要把集群内的k8s的config文件放入本机的 ~/.kube/下。请联系您的系统管理员申请该文件

接下我们尝试进行连接 

~~~ shell
# windows环境直接连接即可
> ktctl connect
00:00AM INF KtConnect start at <PID>
... ...
00:00AM INF ---------------------------------------------------------------
00:00AM INF  All looks good, now you can access to resources in the kubernetes cluster
00:00AM INF ---------------------------------------------------------------

# mac环境下需要使用root权限
$ sudo ktctl connect
00:00AM INF KtConnect start at <PID>
... ...
00:00AM INF ---------------------------------------------------------------
00:00AM INF  All looks good, now you can access to resources in the kubernetes cluster
00:00AM INF ---------------------------------------------------------------
~~~

## 项目搭建

创建正常的SpringBoot项目即可。如果你的SpringBoot版本选型比较低，比如2.2.x或2.3.x那么cloud的版本就要选择Hoxton.x。反之如果你的SpringBoot版本比较新比如2.6.x那么cloud的版本就要选择 2021.x。

|  Boot Version   | Release Train  |
|  ----  | ----  |
| 2.6.x  | 2021.0.x aka Jubilee |
| 2.4.x, 2.5.x (Starting with 2020.0.3)  | 2020.0.x aka Ilford |
| 2.2.x, 2.3.x (Starting with SR5)|Hoxton|
|2.1.x|Greenwich|
|2.0.x|Finchley|

~~~ xml
<!-- 还要注意的是，如果cloud的版本选择Hoxton.的话请引用 这个POM包 -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-all</artifactId>
</dependency>
<!-- 如果cloud版本在2021.0.x POM包请引用  -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-kubernetes-client-config</artifactId>
</dependency>
~~~

### 在k8s中创建 configmap 
首先准备创建configmap，SpringBoot项目要放到configmap中的就是我们的application.yaml文件。我们一般创建confgimap是通过k8s的yaml+项目的yaml合并在生成。这样在持续集成环境每次修改配置，构建后都可以实时的进行变更。
先看一下原始的 application.yaml文件。最简单的配置文件，只包含程序启动时的端口和我们要测试用的两个值。其中setings下的两个值是本次测试使用的，min是本次直接测试configmap读取，mysql-psss是测试从secrets中读取。
~~~ yaml
server:
  port: 8081
setings:
  mysql-psss: ${changedb-url}
  min: 10
~~~
合成后文件

~~~ yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-demo # 指定生成后的configmap名字
data:
  application.yaml: | # 后接文件内容，注意缩进
    server:
      port: 8081
    setings:
      mysql-psss: ${changedb-url}
      min-num: 109
~~~

~~~ shell
# 在K8s中创建configmap
$ kubectl apply -f configmap.yaml -n default
configmap/configmap-demo created
$ kubectl get configmap                  
NAME                      DATA   AGE
configmap-demo            1      7s
~~~

接下来在项目中增加 bootstrap.yml 文件，变更项目的配置文件加载顺序。让程序优先加载 bootstrap。再通过bootstrap来使用k8s中的application.yaml [注2]

~~~ yaml
spring:
  cloud:
    kubernetes:
      enabled: true # 标记使用confgimaps
      config:
        sources:
          - name: configmap-demo # 使用的confgimap名字
      secrets:
        enable-api: true
        sources:
          - name: default-secret # 标记要使用的secret名字
~~~

## 本地测试
为便于演示configmap的加载效果，我们在项目中增加一个Controller
~~~ java 
/**
 * @author guohai
 */
@RestController
public class HomeController {

    @Value("${setings.psss}")
    String pass;
    @Value("${setings.min}")
    String min;

    /**
     * 首页
     * @return 返回读取到的值
     */
    @GetMapping("/")
    public String home() {
        return String.format("%s,%s", pass, min);
    }
}

~~~
要在本地测试环境中使用k8s内的资源，主要需要通过第一步的kt connect来进行连接，给我们的Jvm增加socket的代理。在IDEA中可以修改项目启动参数来实现。
同时还要增加K8S名称空间的环境变量。
![idea settings](/doc-pic/2022/idea-k8s-setings.png)

启动项目，看看效果

~~~ shell
$ curl http://127.0.0.1:8081
password,10
~~~

另外需要注意，当配置了bootstarp优先加载后，项目中的application不再生效。会优先去使用 confgimap中的application配置

## 服务器调试

~~~ sh
# 通过maven构建jar包
$ mvn clean package
# docker打包，因演示机为arm芯片，特在docker build加上了 paltform参数
$ docker buildx build -t gyyx/config-map:1.0 --platform=linux/amd64 .
# 推送镜像到 docker 仓库
$ docker push gyyx/config-map:1.0
# 创建 k8s pod
$ kubectl apply -f k8s-script.yaml
~~~

## 避坑指南

* 整个过程中 secret、configmap当中的key都不要出现下划线，否则会有异常
* 注意SpringBoot和SpringCloud版本的组合，目前本地使用kt connect调试只有 SpringBoot 2.2.x/2.3.x + SpringCloud Hoxton.x 能正常运行，高版本会报 `Not running inside kubernetes. Skipping 'kubernetes' profile activation` 这样的错误。k8s环境内用高版本不会报错

## 备注

* [示例项目](https://github.com/guohai163/configmap-demo)
* [KtConnect](https://alibaba.github.io/kt-connect/#/)
* [使用k8s时bootstrap文件说明](https://docs.spring.io/spring-cloud-kubernetes/docs/current/reference/html/#kubernetes-propertysource-implementations)