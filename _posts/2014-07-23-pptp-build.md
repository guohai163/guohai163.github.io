---
layout: post
title:  "pptp@DigitalOcean配置教程"
date:   2014-07-23 21:59:06
categories: linux pptp vpn
---
pptp是VPN协议的一种，对我来说和l2tp唯一的优点。当某些运营商不允许使用udp协议时pptp的tcp协议依然还能运行。另外相对l2tp来说pptp配置更简单。本次VPN使用的是[DigitalOCean](https://www.digitalocean.com/?refcode=77f588fecae6)的VPS主机。推荐纽约机房，相对北京网速快。另外如果你觉得此篇教程有用并想购买DigitalOcean主机请使用此推广链接购买，也算是对我的支持，谢谢。[https://www.digitalocean.com/?refcode=77f588fecae6](https://www.digitalocean.com/?refcode=77f588fecae6)

###下面为ipsec教程部分###

1. 安装pptpd
	`apt-get install pptpd`
2. 修改`/etc/pptpd.conf`文件。在文件最后追加。

		localip 10.30.0.0
		remoteip 10.30.0.10-100
3. 修改`sysctl.conf`去掉`net.ipv4.ip_forward=1`行注释，后执行`sysctl -p`即可
4. 修改`/etc/ppp/chap-secrets`增加验证用户

		guest	pptpd	"123456"	*
5. 重启pptpd服务 `service pptpd restart`
6. 增加ip转发

		iptables -t nat -A POSTROUTING -s 10.30.0.0/24 -o eth0 -j MASQUERADE
		iptables -I FORWARD -s 10.30.0.0/24 -p tcp --syn -i ppp+ -j TCPMSS --set-mss 1300
