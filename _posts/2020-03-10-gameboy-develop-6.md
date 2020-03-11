---
layout: post
title:  "Gameboy游戏开发⑥-多彩移动背景"
date:   2020-03-10 10:02:02
categories: [develop, gameboy]
tags: [game, develop, gbdk, background]
---
上节课我们通过set_bkg_palette方法来给背景加载了配色方案，但这样整个背景只可以使用一套调色板4种颜色枯燥不？今天的课程就会实现在GBC下每一个瓦块。

### 多彩的GBC世界，怎能少了蓝天白云
首先打开GBTD我们来画朵蓝色的云，因我们期望整体背景是蓝色的，同时也把第0号瓦块颜色修改为蓝色。保存gbr文件并保存一个.c文件。

![bg-cloud](/doc-pic/2020-03/bg-cloud.png)

接下来打开GBMB，加载刚刚保存的gbr文件，重新作画我们的背景地图。并且为了下一步横向移动时用，我们把背景地图修改为32x18个瓦块。左侧的云中间两个同样图形进行的复制
![bgmb-cloud](/doc-pic/2020-03/bgmb-cloud.png)