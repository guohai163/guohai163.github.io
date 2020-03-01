---
layout: post
title:  "Gameboy游戏开发-背景"
date:   2020-02-20 10:02:02
categories: gameboy game develop
--- 
前几节课已经把精灵部分讲的很详细了，接下来我们来讲下一个很重要的部分就是背景。首先我来先看一张原理图，在GB中我们共可以使用三个层。分别是最底层的背景层、之前我们一直在讲解的精灵层、和未来来讲解的窗体层。

![gb_layer.png](//blog.guohai.org/doc-pic/2020-01/gb_layer.png)

背景层的实现原理就是在指定的位置显示指定下标的瓦块，默认的背景一个GB屏幕可以展示20x18个瓦块，为了省事我们也有第三方工具，可以下载[Gameboy Map Builder](http://www.devrs.com/gb/hmgd/gbmb.html)

### 给我们的Mario一个奔跑的平台
首先打开我们的GBTD先画出我们的背景里的平地，然后保存为`background.gbr`。注意做为背景用的瓦块文件下标0的一定要是空白的，下标0的瓦块会做为后续背景的默认瓦块来使用。

![background](//blog.guohai.org/doc-pic/2020-01/gbtd-background.png)

接下来打开我们的新工具GBMB，选择`File->Map properties`把我们的背景大小先设置为20和18，并加载刚刚保存的`background.gbr`文件，我们在第14行循环的把做好的4个背景瓦块分别添加上去。

160×144 
20  18