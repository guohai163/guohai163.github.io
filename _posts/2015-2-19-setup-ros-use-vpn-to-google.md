---
layout: post
title:  "在ROS系统中使用VPN翻越围墙全局访问GOOGLE"
date:   2015-2-19 20:59:06
categories: setup ros use vpn to google
---
墙真的越来越高了,之前跳墙一直在各自设备上使用VPN,但很麻烦 特别是有一些对PPTP或L2TP协议支持不好的设备.一直想全局跳墙,买了个routerboard.实现了全局跳墙。

###科学上网方法###

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
