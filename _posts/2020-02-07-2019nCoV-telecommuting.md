---
layout: post
title:  "远程办公如果全局连回公司网络"
date:   2020-02-07 04:02:02
categories: 2019-nCov china telecommuting
---
今天是已经是放假的第17天了，2019肺炎还没有减弱的趋势，今日截至23点新增确诊3201例。国内大多公司至少是互联网公司目前都是一个远程办公的状态，一般都是给开VPN账号拨号回公司网络。但大多VPN都不支持多播如果有多台设备需要连回去，或者手机需要连回去就比较麻烦了。比较简单的方案就是使用路由器做VPN拨号，但是呢这个非常时期也不是哪个路由器都支持VPN拨号功能，现下单购买目前的物流也是个问题。还有一种解决方案就是用家里的其他电脑或设备拨号，路由器指定一条静态路由把公司的网段路由指向拨号电脑。这也就是传说中的旁线路由，这里为了省电我家用的是树莓派来实现此功能，超省电超稳定。教程使用openVPN来举例，其他方式VPN请举一反三。

### 设置树莓派
这里不一定是要用树莓派，任何安装linux系统的机器/虚拟机也都可以。我的树莓派安装了debian系统使用apt来安装包。首先安装openvpn `apt-get install openpvn`，这步应该很顺利。一般使用openpvn公司会下来一个配置文件加3个证书文件。建议把几个文件合成一份，参考
~~~ config
client
dev tun
proto udp
remote xxx.openpvn.com 12345  
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
keepalive 10 60
route-method exe
route-delay 2
<ca>
此处放CA
</ca>
<cert>
此处放Certificate
</cert>
<key>
此处放key
</key>
~~~
我们把此文件保存为`client.conf`。首先我们进行连接测试，使用命令`openvpn --config client.conf`来进行测试，如果连接失败请联系贵公司网络部负责人^_^。如果连接成功，请把此文件放到`/etc/openvpn/client.conf`下并重启openvpn `service openvpn restart`。该机器即可重启后自动连接远端openvpn服务器。

下来我们来打开该机器的ip转发功能
~~~ shell
# 启用内核进行数据包转发
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
# 修改/etc/sysctl.conf文件里把net.ipv4.ip_forward=1的注释放开，可以永久打开转发功能
# 设置IP FORWARDING和伪装
iptables --table nat --append POSTROUTING --out-interface tun0 -j MASQUERADE
iptables --append FORWARD --in-interface tun0 -j ACCEPT
~~~
支持树莓派这边已经全部操作完。

最后记录下此机器的IP地址，可以通过`ip a`来查看，比如我的派IP为`192.168.101.4`

### 路由器端设置
这里不好举例子我用的routeros的路由比较特殊。我在网上搜了几个教程，大家看看哪表更适合你。所有路由表里目的IP是你公司的内部网段，网关是刚刚配好的那台机器。

* [TP-LINK的静态路由设置](https://service.tp-link.com.cn/detail_article_28.html)
* [DLINK路由器，请看41页](http://support.dlink.com.cn/download.ashx?file=525)

其他更多请看你的路由器说明书。