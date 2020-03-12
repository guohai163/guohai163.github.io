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

接下来打开GBMB，加载刚刚保存的gbr文件，重新作画我们的背景地图。并且为了下一步横向移动时用，我们把背景地图修改为32x18个瓦块。
![bgmb-cloud](/doc-pic/2020-03/bgmb-cloud.png)

导出这块这之前有点区别，在`Location format`内增加一个GBC Palette属性Bits选为3。在右侧的`Plane count`变更为2 planes(16bit)，Plane order改为Planes are continues。都选完后可以看到结果面板会有所变化，点击OK导出.c和.h文件即可。
![cloud-export](/doc-pic/2020-03/cloud-export.png)

我们打开新生成的`mario-bg.c`文件，可以看到从之前的marioBG一个数组变成了marioBGPLN0和marioBGPLN1两个数组，其中marioBGPLN0依然存放的是瓦块的下标，marioBGPLN1存放的是改位置使用的调色板下标。我们看下在项目中如何使用打开上节课的main.c文件

~~~ c
// 新增加的背景配色数组
const UWORD bkgpalette[] = {
    backgroundCGBPal0c0,
    backgroundCGBPal0c1,
    backgroundCGBPal0c2,
    backgroundCGBPal0c3,

    backgroundCGBPal1c0,
    backgroundCGBPal1c1,
    backgroundCGBPal1c2,
    backgroundCGBPal1c3,

    backgroundCGBPal2c0,
    backgroundCGBPal2c1,
    backgroundCGBPal2c2,
    backgroundCGBPal2c3,
};

// main方法内增加
    
// 设置背景数据源
set_bkg_data(0,31,background);
// 切换到寄存器1准备加载配色数据
VBK_REG = 1;
//加载背景配色数据
set_bkg_tiles(0,0,marioBGWidth,marioBGHeight,marioBGPLN1);
// 切换到寄存器0准备加载瓦块下标数据
VBK_REG = 0;
// 加载瓦块下标数据
set_bkg_tiles(0,0,marioBGWidth,marioBGHeight,marioBGPLN0);

//加载背景配色方案
set_bkg_palette(0, 3, bkgpalette);
//调用显示背景方法
SHOW_BKG;
~~~
`make run`

![cloud-mario](/doc-pic/2020-03/cloud-mario.png)

### 如何实现横版动作游戏

【未完】