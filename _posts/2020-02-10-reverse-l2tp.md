---
layout: post
title:  "反向L2TP拨号，接入公司网络"
date:   2020-02-10 10:02:02
categories: [network, routeros, 2019-nCov] 
tags: [telecommuting, 2019-nCov, china, routeros]
---

2019肺炎还没有结束，今天第一天远程复工，前几天介绍了一个全局连回公司网络的方案。但有人私信我，公司没有为了临时办公搭建VPN的准备，大多公司的临时解决方案是用TeamViewer类软件来实现远程连接方案。这类方案基本都不是直连状态，都是需要去第三方公司绕一圈再连上，第一会卡顿特别是同一公司多人在使用的情况下，更关键的这绕了一圈安全性也不好说。那有没有其他的解决方案呢？

咱们可以反向VPN，即从家中搭建VPN服务器，从公司向家中进行拨号。当然也相对的需要家中有公网IP，如果你使用的三大运营商的宽带但目前没有公网IP，可以私信我。另外此教程为Routeros路由器系列教程，所以需要你至少拥有一个Routeros系统的路由器。

### 路由到PC的方式

![routeros-pc.png](//blog.guohai.org/doc-pic/2020-02/routeros-pc.png)

这种方式适合只需要连接到公司一台机器上，比较适合不需要连公司内部其他机器的情况。首先我们来设置Home端。

~~~ shell
//首先我们来创建l2tp用户
[admin@Home] /ppp secret> add name=Home service=l2tp password=123
local-address=172.16.1.1 remote-address=172.16.1.2
//接下来我们来启动Home端的l2tp服务
[admin@Home] /interface l2tp-server server> set enabled=yes
~~~

办公室这边的台式机比较简单，直接用系统自带的l2tp方式拨号即可。截图为windows10的配置示例，当拨号成功后，在home这端使用172.16.1.2即可连接公司的PC机

![windows l2tp](//blog.guohai.org/doc-pic/2020-02/WX20200210-233029.png)

### 路由器到路由器的方式

![routeros-routeros.png](//blog.guohai.org/doc-pic/2020-02/routeros-routeros.png)

这种方式比较适合除了要连接公司的台式机以外，还要连接公司内部其他服务器。

Home的设置同上，不再做讲解。我们来设置Offcie端的路由器。

~~~ shell
//在公司端添加拨号客户端
[admin@Office] /interface l2tp-client> add user=Home password=123 connect-to=Homeserver.ip disabled=no
~~~

拨号成功后家庭内部的电脑已经能访问公司的主机，如果要继续访问公司端的全部网络还要再增加router和nat

~~~ shell
//首先增加公司端的路由
[admin@Home] /ip route> add dst-address=10.1.0.0/16 gateway=172.16.1.2
//其次增加NAT
[admin@Home] /ip firewall nat> add action=masquerade chain=srcnat comment=comp-ppp out-interface=<l2tp-Home>
~~~

至此在家里办公就可以正常访问公司的内部网络了。

### 其他

2000年接触互联网的时候就听过SOHO(Small Office，Home Office)这个词，当时觉得很新鲜一直很向往。没想到20年后的春节因为一场疫情，全国互联网公司都实现了一场在家远程办公的状态。如果不考虑疫情这件事，SOHO的状态你喜欢吗？

