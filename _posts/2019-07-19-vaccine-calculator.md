---
layout: post
title:  "哪些二类疫苗比较值得打？"
date:   2019-07-19 22:59:06
categories: [baby]
tags: [vaccine, calculator, Java, spring]
---

## 二类疫苗擱建议

1. 肺炎疫苗：PCV13[13价肺炎疫苗],由肺炎链球菌（S. pneumoniae，即肺炎球菌）引发的疾病已成为全球一个重要的公共卫生问题。肺炎球菌诱发的严重疾病包括肺炎、脑膜炎和发热性菌血症等。严重的肺炎球菌疾病还可能导致耳聋、瘫痪、智力低下等严重后遗症。2005年，WHO估计全球每年有160万人死于肺炎球菌疾病，包括70-100万5岁以下的儿童。基础免疫在2、4、6月龄各接种1剂，加强免疫在12～15月龄接种1剂。
2. 轮状病毒疫苗:症状主要是腹泻。但传染性超强，有的是和患病的孩子玩了一会就中枪了，有的只是去医院看感冒就被传染上了。目前国内社区医院主要用的是兰州生物的罗特威。口服即可，建议2月龄到3岁幼儿每年一次。
3. 其它建议：手足口病疫苗、水痘疫苗、流感疫苗。


## 附实用小程序-新生儿疫苗接种时间表

 先说一下这个小程序的功能：首页可以看到2016年版（目前实施）国家免疫规划疫苗儿童免疫计划表，这是必须接种疫苗，之后输入你家娃的出生日期，以及你想接种的二类疫苗。点击提交，程序会帮你重新计算疫苗接种时间表，如果你选择的二类是可以替代一类的，会把相应的一类疫苗进行隐藏。同时会按出生时间帮你计算已经接种过的疫苗，当月应该要接种的，以及未来还未接种的疫苗。你也可以选择把最终页面的URL进行收藏，之后随时打开都可以看到当前接种计划安排。全程建议横屏使用

![vaccine-p1](http://blog.guohai.org/doc-pic/2019-07/vaccine-p1.png)

 首先打开网址[http://vaccine.guohai.org](http://vaccine.guohai.org)或直接点击阅读原文按钮，会跳转到程序首页。列出所有的国家免疫计划里的疫苗。点击下一步

![vaccine-p2](http://blog.guohai.org/doc-pic/2019-07/vaccine-p2.png)

在此页面请先选择您准备接种的二类疫苗【二类疫苗数据还在整理中】，以及选择您家娃的出生日期，点击提交

![vaccine-p3](http://blog.guohai.org/doc-pic/2019-07/vaccine-p3.png)

最终页面会按您选择的二类疫苗和一类疫苗进行整合出一个新的列表，列表中的绿色列为已过日期，红色列为当前月份需要接种的时间，蓝色列表为未来要接种的疫苗。

整个程序使用Spring boot框架进行快速开发，源码已经放在github上。[https://github.com/guohai163/vaccine](https://github.com/guohai163/vaccine)
