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

![background](//blog.guohai.org/doc-pic/2020-03/gbtd-background.png)

接下来打开我们的新工具GBMB，选择`File->Map properties`把我们的背景大小先设置为20和18，并加载刚刚保存的`background.gbr`文件，我们在第14行循环的把做好的4个背景瓦块分别添加上去。

![bg-gdmb](//blog.guohai.org/doc-pic/2020-03/bg-gdmb.png)

接下来我们进行导出操作，选择 `File->Export to` `Standard`标签下没有什么特别的选好路径即可，我们在Location Format标签下要新增一个Tile number属性并把Bits设置为8bit，在`Map Layout`下我们选为按`Rows`进行排列   在`Plane count`下选为`1 Plane(8 bits)`。详细的可以看图

![bg-export](//blog.guohai.org/doc-pic/2020-03/gdmb-export.png)

现在我们手里应该有两对背景.c.h文件，分别是gbtd和gbmb产生的。

### 编译我们的项目
在我们上节课的例子里的main方法中加入如下代码,这里要注意因为上节课我们把ROM已经编译成了CGB的，所以 我们今天加背景的时候也要加上调色方案，否则背景不会显示出来。

~~~ c

    //设置背景数据源
    set_bkg_data(0,23,bg);
    //加载背景数据
    set_bkg_tiles(0,0,marioBgWidth,marioBgHeight,marioBg);
    //加载背景配色方案
    set_bkg_palette(0, 1, bkgpalette);
    //调用显示背景方法
    SHOW_BKG;
    
~~~

`make run`

![color-bkg.gif](//blog.guohai.org/doc-pic/2020-03/color-bkg.gif)


### 源码下载

* [彩色背景源码](//blog.guohai.org/doc-pic/2020-03/gb5.zip)

---

如果觉得文章内容比较实用，获得后续更新通知请关注公众号：

![guohaiqr.jpg](//blog.guohai.org/doc-pic/guohaiqr.jpg)