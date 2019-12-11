---
layout: post
title:  "Nexus Repository私服挂了后怎么办？"
date:   2019-09-09 22:59:59
categories: spring aliyun oss
---

团队内一直使用Nexus Repository搭建的私服为大家做包下载的加速，以及团队内自己的包管理。上个周末因为机房停电服务异常关机，周一上班后再开机服务死活起不来了。查看日志发现报错`OStorageException: Cannot open local storage '/data1/sonatype-work/nexus3/db/accesslog' with mode=rw`第一反应是文档没有权限读写，或被其他进程占用，把权限加到777了也无效，也没有其他进程在占用。开G搜了下大多提示就是DB损坏了修复云云，试了几个修复方案都不行，使用控制台加载OrientDB也是报同样错误。然而又没有进行过备份.....只能告诉同事一个好消息一个坏消息：好消息是我们的Nexus升级到了最新版本，界面又漂亮了点。坏消息是旧的Nexus挂掉了。

## 恢复数据
代理加速的仓库我们直接配置好就行，等着慢慢同步即可。私有包我们团队使用Nexus主要存jar/dll,从Nexus2用过来也6、7年了。让团队成员手工一个一个传太恐怖了。这里我分别讲解一下maven和Nuget的还原方式。

### Maven的还原
在开发人员或构建服务器的~/.m2下会有完整的使用过的maven仓库，使用命令`mvn deploy:deploy-file`即可重新传上去，但这东西不可能人为完成。mvn命令还需要包的groupId、artifactId、version等信息，这个东西在pom文件里会有。目前我们需要两个过程：1. 遍历目录找到所有的jar+pom文件 2. 解析pom文件找到里面的关键值拼成一个命令串执行。

第一想法就是用shell脚本来解决，遍历目录容易。pom文件是XML格式的，解析XML文件 shell好像有点弱。网上搜了下大多解决方案都是使用python但我不会，只能现学了还好大多语言语法规则查不多。在执行前先要配置一下执行机器的`~/.m2/settings.xml`文件，需要增加一个servers节点，里面要包括一个有权限上传jar包的私有库的账号。

放最终完成的脚本 ：
~~~ python
#!/usr/bin/python
# -*- coding: UTF-8 -*-

from xml.etree.ElementTree import parse
import os,re

# 要进行处理的目录
rootdir = '~/.m2'
# 仓库的URL，要指向hosted类型的库
repository = 'https://lib.company.com/repository/company-maven/'
# ~/.m2/settings.xml文件中server标识的名字
servertag = 'server001'

# 正则准备匹配的文件名
pomprog = re.compile('.*.pom$')
jarprog = re.compile('.*.jar$')

# pom文件解析以及发布，参数1为pom文件，参数2为jar文件
def mvnupload(pomfile,jarfile):
    groupId = ''
    artifactId = ''
    version = ''
    u = open(pomfile)
    doc = parse(u)

    root = doc.getroot()
    # 解析XML中出现的关键值并暂存。
    for child in root:
        if child.tag == '{http://maven.apache.org/POM/4.0.0}groupId':
            groupId = child.text
        if child.tag == '{http://maven.apache.org/POM/4.0.0}artifactId':
            artifactId = child.text
        if child.tag == '{http://maven.apache.org/POM/4.0.0}version':
            version = child.text
    if groupId != '' and artifactId != '' and version != '':
        # 拼接出上传命令
        cmd = 'mvn deploy:deploy-file -DgroupId='+groupId+' -DartifactId='+artifactId+' -Dversion='+version+' -DgeneratePom=false -Dpackaging=jar -DrepositoryId='+servertag+' -Durl='+repository+' -DpomFile='+pomfile+' -Dfile='+jarfile
        print cmd
        # 执行命令
        os.system(cmd)

# 遍历目录方法，参数为根目录
def traversal(dir):
    pomfile = ''
    jarfile = ''
    flagE = True
    for list in os.listdir(dir):
        path = os.path.join(dir,list)
        if os.path.isfile(path):
            # 当发现pom或jar文件时先进行暂存
            if not pomprog.match(path) is None:
                pomfile = path
            if not jarprog.match(path) is None:
                jarfile = path
            # 当找全两个文件时，进行解析操作
            if pomfile != '' and jarfile != '' and flagE:
                mvnupload( pomfile, jarfile)
                flagE = False
        if os.path.isdir(path):
            traversal(path)

traversal(rootdir)
~~~

此脚本可以无限执行，仓库里已经存在的包不会重复上传，建议先在构建服务器上执行过，再找几个主力开发在他们的机器上执行一下，尽量补全jar包。

### Nuget仓库的还原
与上面的方法类似在构建服务器上，每个项目下会有一个名字为Packages的目录，该目录下会有Nuget仓库里需要使用的nupkg文件。但nuget的上传不是依赖账密，而是是使用安全码，登录你的Nexus OSS系统。点击你的账号，会有一个NuGet API Key按钮点击下可以获得一个密钥串，一定要保存好脚本中需要使用到。依然放脚本：
~~~ python
#! python
# -*- coding: UTF-8 -*-
import os,re
# 要扫描的根目录 
rootdir = 'd:\\sources'
# 上面提到的密钥串
key = 'e1d4c9e0-e55f-3da2-97b6-xxxxxxxxxx'
# 仓库的URL
url = 'https://lib.company.com/repository/company-nuget/'

# 需要上传的文件 ，正则，我们公司自己的nuget包都会以公司名开头，其他名字的包不需要上传
nugetprog = re.compile('^Company.*.nupkg$')

# 遍历目录找出符合条件的nupkg文件
def traversal(dir):
    nugetfile = ''
    for list in os.listdir(dir):
        path = os.path.join(dir,list)
        if os.path.isfile(path):
            # print path
            if not nugetprog.match(path) is None:
                cmd = 'nuget push '+path+' '+key+' -source '+url
                print cmd
        if os.path.isdir(path):
            traversal(path)


traversal(rootdir)
~~~

## 防范于未然
即使使用了上面的方案，也只能恢复80%左右的包。最根本的做法还是做好备份工作。Nexus2是使用文件存储，之前只需要备份好storage目录就行。但是到了3.0后开始使用OrientDB+blob的方式组织存储文件了。两个都需要备份。blob只需要当文件存储的方式拷贝出来一份即可。OrientDB在Nexus的后台可以使用Task进行定时备份。异地恢复的方式：
    1. 先停止Nexus服务
    2. 清空`$data-dir/db`下的文件
    3. 将备份好的blob拷贝过回
    4. 拷贝DB的备份文件到`$data-dir/restore-from-backup`下（3.10.0以前版本请拷贝到`$data-dir/backup`下）
    5. 重启你的服务就会恢复完成