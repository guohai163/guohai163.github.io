---
layout: post
title:  "在ROS系统中使用VPN翻越围墙全局访问GOOGLE"
date:   2015-2-19 20:59:06
categories: setup ros use vpn to google
---
墙真的越来越高了,之前跳墙一直在各自设备上使用VPN,但很麻烦 特别是有一些对PPTP或L2TP协议支持不好的设备.一直想全局跳墙,买了个routerboard.实现了全局跳墙。

### 科学上网方法

1. 创建PPTP连接

	/interface pptp-client
	add connect-to={vpn ip} disabled=no mrru=1600 name=pptp-out1 password=\
	    {password} user={user}

2.  对路由数据进行标记，非中国IP全部走VPN。 [中国IP列表](http://guohai163.github.io/doc-pic/ros/china-ip.rsc)
	
	import file=china-ip.rsc

3. 设置标记
	
	/ip firewall mangle
	add action=mark-routing chain=prerouting dst-address=!192.168.88.0/24 \
	    dst-address-list=!novpn dst-address-type=!local in-interface=ether2-lan \
	    new-routing-mark=vpn

4. 增加路由规则

	/ip route
	add distance=1 gateway=pptp-out1 routing-mark=vpn

5.  增加NAT规则

	/ip firewall nat
	add action=masquerade chain=srcnat dst-address-list=!novpn out-interface=\
    	pptp-out1


简单吧，就这么几步即可，如果你有多个远程VPN服务器还可以考虑使用PCC来进行负载均衡。

--

### 功能补充

按以上方法可以实现指定IP走VPN。但使用后发现问题

1. 墙上还有一个功能DNS污染。解决方案：DNS污染就是让去国外DNS时也走VPN通道。

2. 第一问题解决完紧接问题又出现了，因为走的是国外DNS国内网站也会被解析到境外服务器，国内网站 速度会变慢。解决方案：使用第七层协议拦截指定域名的解析，只有指定域名走8.8.8.8的DNS。其它域名正常走ISP的解析服务器。
```
	/ip firewall layer7-protocol
	add comment="Redirect GFWed based DNS requests to google DNS" name=\
	    to_google_DNS regexp="google.com|twitter.com|youtube.com|ytimg.com|blogger\
	    .com|blogspot.com|wordpress.com"
	/ip firewall mangle
	add action=mark-routing chain=prerouting comment="dns mangling to google dns" \
	    dst-port=53 in-interface=ether2-lan layer7-protocol=to_google_DNS \
	    log-prefix=abcc new-routing-mark=to_google protocol=udp
	add action=mark-routing chain=prerouting comment="dns mangling to google dns" \
	    dst-port=53 in-interface=ether2-lan layer7-protocol=to_google_DNS \
	    log-prefix=abcd new-routing-mark=to_google protocol=tcp
	/ip firewall nat
	add action=dst-nat chain=dstnat log=yes log-prefix=def protocol=udp \
	    routing-mark=to_google to-addresses=8.8.8.8 to-ports=53
	add action=dst-nat chain=dstnat protocol=tcp routing-mark=to_google \
	    to-addresses=8.8.8.8 to-ports=53
```
3. VPN毕竟在国外，单个VPN太慢怎么办？解决方案：多VPN负载均衡
