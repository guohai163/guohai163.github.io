---
layout: post
title:  "在家庭网络中使用RouterOS路由器全局翻墙"
date:   2020-01-01 01:59:06
categories: [routeros, vpn]
tags: [routeros, vpn, gfw]
image: /doc-pic/2020-03/ros-l2tp/youtube.png
---
因我的BLOG托管在github上无法看到访问数据，这几天心血来潮给我的BLOG上挂了个站点统计脚本。发现被访问最多的文章是2015的[在ROS系统中使用VPN翻越围墙全局访问GOOGLE](/setup/ros/use/vpn/to/google/2015/02/19/setup-ros-use-vpn-to-google.html)相隔5年我再看这个文章觉得写的太粗，而且文章里有的地方在目前的网络情况下已经不可用了。所以我来更新文档来了。

先看下图是我们要实现的方案，首先我们需要在境外租用一个VPS做我们的跳板。推荐[vultr.com](https://www.vultr.com/?ref=8414686-6G)东京机房一个月5美金，使用我的推广链接新用户首充送100美金，好了广告结束。设置好后那些报404的网站的域名走VPN线路到达VPS后去8.8.8.8的这个DNS进行域名解析。解析后的IP路由器分析后会让这些IP继续走VPN线路经过VPS去访问，让404的站点回复正常。而普通的网站呢，还是走国内的你的运营商的DNS进行解析。解析得到IP后，ROS分析是普通IP后，直接去往服务器。这么做的好处

1. 404网站的域名在走到VPS后进行解析，杜绝了域名污染的问题
2. 只有报404网站的IP走VPS后进行访问，节省VPS的流量，让正常的网站不用去国外绕一圈
3. 普通网站的域名在你的运营商进行解析，解析到的IP肯定是到你延迟最低的服务器，保证普通网站能利用上各种CDN加速。
4. 以上所有设置只需要在ROS上进行设置，设置后全家享受。包括像Apple TV这种不具备翻墙功能的简单设备也可以正常使用了
![ros-vpn.png](/doc-pic/2020-03/ros-vpn.png)

本教程主要针对RouterOS系统的路由器，所以你需要准备一个。

### VPS环境搭建

先说服务器的地区选择，推荐香港>台湾>日本的服务器。台湾的网速也挺棒的但目前好像只有谷歌云在台湾有服务器，VPS虽然不贵，但是谷歌到大陆的流量相对会贵一些，另外访问谷歌云的页面也需要先翻墙才可使用，有点麻烦推荐已经搞定翻墙后再去这里申请个主机新用户有300没金赠送。香港：阿里云腾讯云在此都有机房但价格也不低，带宽低。日本东京挺多5美金一个月的主机流量1TB/月基本用不完，重点推荐。我之前是Linde用户后来他们的东京1机房强制下线迁移到东京2后ping延迟很糟糕。目前推荐[vultr.com](https://www.vultr.com/?ref=8414686-6G)东京机房。

另一个推荐的角度延迟丢包率是否绕路，按上面的方法申请完主机后会得到主机的IP地址使用ping进行测试，建议至少测试1000个包，看下平均延迟是否能到100ms以下，丢包率是否能低于5%。另外可以用traceroute命令来看看从你的路由器到VPS的路径是否有绕远，比如从北京到东京如果中间出现美国的IP那就会严重的绕路，这种情况下不要选择。

![ping](/doc-pic/2020-03/ros-l2tp/ping-time.png)

![traceroute.png](/doc-pic/2020-03/ros-l2tp/trace.png)
上面两个截图是本次演示用的主机，在晚高峰时我测试了1000个包，可以看到平均延时在100ms左右，丢包率1%还算可以接受。我们又看了下路由走向，从北京出发走上海的出海光缆直接到达东京，并没有绕路情况可以接受。

选择好主机后我们开始选择VPN方案旧文章推荐使用的PPTP协议目前应该已经完成无法使用了，而且iOS9后也认为这种管道协议不安全不再支持，目前推荐l2tp协议。我这里有一个已经写好的脚本，服务器的系统推荐选择Debian 9。[l2tp脚本](/doc-pic/2020-03/l2tp-server.sh)

因为我们服务器的22口会对公网开放，服务器刚申请完就会有人扫描你的22口并尝试用字典登录。为了安全申请完服务器后第一件要做的事就是把自己的公钥传到服务器以后一律使用公私钥的方式登录。并把root的密码登录方式关闭掉。接下来我们准备在服务器上开始执行上面的l2tp-server脚本。

~~~ shell
root@vps-server:~$ wget http://blog.guohai.org/doc-pic/2020-03/l2tp-server.sh -O l2tp-server.sh
root@vps-server:~$ sh l2tp-server.sh
# 脚本会开始检测系统环境，并开始自动安装软件包。最后会帮你创建好一个默认用户：
================================================

IPsec VPN server is now ready for use!

Connect to your new VPN with these details:

Server IP: 110.110.110.110
IPsec PSK: xZRAVStKZUp3dqrc
Username: vpnuser
Password: 6mrNJcLiVnVpUXn9

Write these down. You'll need them to connect!

Important notes:   https://git.io/vpnnotes
Setup VPN clients: https://git.io/vpnclients

================================================
~~~
以上设置好后，我们可以先把我们的手机按以上提示进行设置测试。并且这样离开ROS环境下也可以正常访问报404的网站了。

### 在RouterOS上增加隧道

1. 首先我们创建一个l2tp拨号的连接，直接打开[winbox客户端](https://mikrotik.com/download)选择左侧的PPP菜单。
![create-l2tp-1](/doc-pic/2020-03/ros-l2tp/create-l2tp.png)
2. 我们先给本连接起个名字，因为机房在东京我们直接就叫l2tp-tokyo。选择Dial Out标签，并按上一步得到的连接信息进行填空。填空完毕点击Apply很快就可以在右下角看到连接成功的信息。
![l2tp-dial](/doc-pic/2020-03/ros-l2tp/l2tp-dial.png)
3. 现在我们导入确定不走VPN线路的IP进去。如果你的macOS或Linux系统下面命令可以直接执行，如果你是windows系统，请在上步申请的主机上执行，最终把文件导回本地。
[*成品novpn-ip下载,2020年3月数据*](/doc-pic/2020-03/ros-l2tp/novpn-ip-list-202003.zip)

    ~~~ shell

    # 首先前往亚太互联网络信息中心下载亚太地区IP地址列表
    root@vps-server:~$ wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
    # 创建导入用的文件，并存入第一行
    root@vps-server:~$ echo "/ip firewall address-list" > novpn-ip-list.rsc
    # 使用正则把所有标记为CN的地址存入我们即将导入的文件中
    root@vps-server:~$ grep "|CN|ipv4" delegated-apnic-latest | awk -F'|' '{print "add address="$4"/"32-int(log(int($5))/log(2))" disabled=no list=novpn-ip"}' >> novpn-ip-list.rsc
    # 存入一些目前已经确定不需要走VPN的大段IP
    root@vps-server:~$ echo "add address=17.0.0.0/8 disabled=no list=novpn-ip comment=apple-ip" >> novpn-ip-list.rsc
    root@vps-server:~$ echo "add address=10.0.0.0/8 disabled=no list=novpn-ip comment=Private-ip" >> novpn-ip-list.rsc

    # 删除临时文件
    root@vps-server:~$ rm delegated-apnic-latest
    ~~~
    得到novpn-ip-list.rsc文件后，我们需要放到ROS的File下。
![upload-file.png](/doc-pic/2020-03/ros-l2tp/upload-file.png)
4. 导入IP地址列表只支持终端方式，在Winbox内打开新终端，并键入`import file=novpn-ip-list.rsc`稍后导入成功后可以去 `IP->Firewall->Address Lists` 下看结果。
![import-iplist.png-](/doc-pic/2020-03/ros-l2tp/import-iplist.png)
5. 为需要走VPN的数据包打上标记，打开 `IP->Firewall->Mangle`创建一个新的Mangle规则。General标签下：Chain选为prerouting;并在目标地址上把局域网地址屏蔽掉；输入接口选为内网网桥。Advanced标签下：目标地址列表选为非刚刚导入的novpn-ip列表。Extra标签下：目标地址类型勾选非本地。Action标签下：Action选为标记路由，并给起一个mark名字`to-vpn-ip`。 不清楚的地方可以看下截图。
![mark-route.png](/doc-pic/2020-03/ros-l2tp/mark-route.png)

6. 增加专属静态路由规则，打开 `IP->Routes` 添加一条新路由规则。目标地址为0.0.0.0/0；Gateway选为之前创建的l2tp拨号名；Check检查建议勾选上当l2tp拨号异常时可以自动作废此条路由规则；Distance填写1一定要比默认路由优先级高；Routing Mark选为刚刚打好标记的名字。
![add-route.png](/doc-pic/2020-03/ros-l2tp/add-route.png)

7. 因为我们这个还是用内部IP向外部访问，还是要增加一条NAT地址转换，点击 `IP->Firewall->Nat` 增加一条NAT规则。General标签下：Chain选择srcnat;Out Interface选择刚刚新建的l2tp拨号名字。Action标签下：Action选择为masquerade。即可
![add-nat](/doc-pic/2020-03/ros-l2tp/add-nat.png)

8. 测试第一阶段结果，使用traceroute分别检查114.114.114.114(*NanJing XinFeng Information Technologies, Inc*)和8.8.8.8(*Google LLC*)的路由走向。

    结果可以看到，国内的IP会正常的走旧的路由节点。国外的IP路由节点会改过从咱们新搭建的隧道通过。
![trace-test-8-114.png](/doc-pic/2020-03/ros-l2tp/trace-test-8-114.png)

### 让部分域名也可以通过隧道后进行解析

这时我们使用浏览器打开 [ifconfig.io](https://ifconfig.io/) 可以看到检测页面的IP显示已经不是你宽带运营商的IP已经显示为VPS主机的IP了，到此证明我们的隧道已经打通。我们再次敲入[google.com](https://www.google.com)发现还是打不开，我们使用`nslookup www.google.com`查一下现在解析回来的IP并把此IP放在网上查了下发现这个解析出来的IP并不属于Google公司。看来是我们的运营商的DNS服务器有问题，但是如果我们直接把ROS里的DNS服务器改成8.8.8.8的话虽然google.com能解析回正确的IP地址，但国内的这些网站解析回来的不一定是最快的离你最近的机房了，可能你用的电信线路但帮你解析出来的是一个联通CDN机房的IP。怎么办？我们可以在ROS里做域名解析劫持。

1. 为指定的域名的解析请求打上标记。幸好我们的ROS支持第7层协议，可以通过正则来解析包内的数据。首先在 `IP->Firewall->Layer7 Protocols`内增加一个新的规则。Regexp内填入你希望ROS来进行劫持的域名即可。
![add-l7.png](/doc-pic/2020-03/ros-l2tp/add-l7.png)
然后打开Mangle,添加一个新的mark规则。在General标签下：Chian选为prerouting,Protocol选为udp，dstport选为53,输入接口选为内网网桥。Advanced标签下：L7协议勾选为刚刚新建的规则。Action标签下：Action选为mark routing,再起一个名字即可。
![dns-mangle.png](/doc-pic/2020-03/ros-l2tp/dns-mangle.png)

2. 接下来打开NAT我们对打标记的数据包做一个劫持。General标签内:Chain选为dstnat,RoutingMark选为上一步打的标记。Action标签内：Action选为dst-nat，To Address是劫持后的目标服务器我们写为8.8.8.8，To Ports为目标端口我们写为53.
![dns-nat.png](/doc-pic/2020-03/ros-l2tp/dns-nat.png)

3. 好了，现在打开我们期盼的油管看看：
![youtube.png](/doc-pic/2020-03/ros-l2tp/youtube.png)