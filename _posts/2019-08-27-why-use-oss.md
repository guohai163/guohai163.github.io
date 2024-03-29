---
layout: post
title:  "我的项目为什么要使用对象存储"
date:   2019-08-27 22:59:59
categories: [operations, develop]
tags: [spring, aliyun, oss]
---
对象存储服务（Object Storage Service，OSS）是一种海量、安全、低成本、高可靠的云存储服务，适合存放任意类型的文件。容量和处理能力弹性扩展，多种存储类型供选择，全面优化存储成本。

那在我的项目中为什么不用自己的服务器存储对象而要接第三方呢？

||传统方式|对象存储|
|--|--|--|
|成本|自己租VPS的存储空间价格会更高，无法不停机进行扩容，可能是单线接入|单价低，存储0.1元/GB/月。流量0.25-0.5元之间,BGP线路全国到机房ping值都能在50ms以里。部分厂商[阿里、腾讯]还有免费使用额度|
|可靠|为了成本可能是单一机器，硬盘有损坏的可能，VPS厂商最多赔你几个小时的免费使用可不管你的数据。|但大多的对象存储都让数据可靠性达到99.99999%【阿里家说是12个9】|
|其它|自己的项目如果是在负载均衡状态会部署多份无法保证每次轮询到哪台机器上，还需要自己做数据同步。|对象存储不会面临此问题|

说了这么多对比如果你的项目决定用了，就继续往下看吧。目前我们的jblog项目就涉及到了用户上传图片的功能，我们经多方考虑最后计划使用阿里家的对象存储。接入方案有三种1.客户端直接进行参数签名然后上传，2.用户数据提交给应用服务器后应用服务器签名上传，3.服务器进行签名然后把签名返还给客户端，客户端进行上传。前两种方案最简单省事，但方案1会把私钥泄漏到客户端对外的项目有隐患，方案2虽然安全了，但是用户的数据要先上传应用服务器性能或速度不理想。方案3虽然麻烦点但是在安全和性能上是对公网项目的最优选择。

## 开始接入

1. 首先要做的就是注册账号开通服务获得AccessKeyId和AccessKeySecret。这里不建议使用默认账号的AK对权限太高可以去控制台里的RAM访问控制申请一个只有OSS管理权限的新账号。这里要注意AccessKeySecret一定要保存好一次获得后期如果丢失只能再次申请。

2. 创建好账号我们就是开通OSS服务，同时创建一个新的Bucket,起名称、选区域，选项要选成公共读这样你上传的内容其它人才可以直接访问。
![create bucket](http://blog.guohai.org/doc-pic/2019-08/WX20190828-162954.png)

3. 接下来我们开始程序部分，我只放了关键部分的说明，完整部分请到git仓库内查看。我们先来看前台代码

首先我们在页面里放几个必要的元素，一个预览图的div两个按钮一个用来浏览文件一个用来点击上传，可能还需要一个异常时的提醒框
~~~ html
<ul id="filelist"></ul>
<span id="upload-console"></span>
<button type="submit" id="browse" class="btn btn-info js_start">浏览文件</button>
<button type="submit" class="btn btn-info js_start" id="start-upload">上传头像</button>
~~~
这里我们使用了一个第三方的JS插件[plupload](https://www.plupload.com)
~~~ javascript

var uploader = new plupload.
~~~
