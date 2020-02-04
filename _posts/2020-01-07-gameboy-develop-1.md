---
layout: post
title:  "Gameboy游戏开发-搭建环境"
date:   2020-1-1 1:1:1
categories: gameboy game develop
---

Gameboy是80、90后童年曾经陪伴过的掌上游戏机，给我们儿时带来了很多欢乐。我还记得我的GB是96年时用压岁钱买的，当时从父母那里收了200的压岁钱，自己用平时积攒的200块钱自己坐了2个小时的车去了大城市锦州买的这台游戏机。当时已经没有钱再买游戏卡了，还是从我们这叫老六那租的游戏卡一块钱一天。当时也想好奇过GB上的游戏是怎么做出来的？好奇归好奇那个年代信息闭塞不太可能知道答案。

![gameboy picture](//blog.guohai.org/doc-pic/2020-01/oldgb.jpg)

今天互联网发达了，我儿时的梦想也算可以实现了。GB的原生开发都是使用汇编语言操作z80CPU，但汇编的学习曲线有点长，网上有人做了个c语言的封装类库。虽然执行效率要比汇编差点，但我们又不做太大型的游戏不会出现太大的差别。

### 环境搭建

#### Windows下环境搭建
首先推荐大家下载[MinGW](https://osdn.net/projects/mingw/releases/)，可以让windows也支持Makefile文件方便项目的编译。默认下载完成后是一个MinGW的安装管理工具，我们只勾选下载mingw32-bas-bin即可
![MinGW Installation Manager](//blog.guohai.org/doc-pic/2020-01/mingw.png)
安装完成后我们会在C:\MinGW\bin\下增加一个mingw32-make.exe我们这次主要使用这个（下面的所有操作都在命令行下完成）为了方便使用，我们可以先给mingw32-make创建一个符号链接。`mklink make.exe mingw32-make.exe`接下来我们把C:\MinGW\bin\目录下到系统Path下。然后咱们在命令行中试下`make -v`如果有如下输出代表第一步安装成功
``` shell
C:\Users\hai>make -v
GNU Make 3.82.90
Built for i686-pc-mingw32
Copyright (C) 1988-2012 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```
接下来我们来安装gbdk，可以去[官方网站](http://gbdk.sourceforge.net/)下载。下回来的是一个zip的压缩包，直接解压到一个目录就可以推荐解压到C盘，我这里演示环境放到了`C:\tools\gbdk`下面，在系统环境变量path里增加一个地址`c:\tools\gbdk\bin\`加好环境变量后在任意目录敲一下`lcc -v`会有如下输出
``` shell
C:\Users\hai>lcc -v
lcc $Id: lcc.c,v 1.5 2000/03/27 00:56:12 michaelh Exp $
```

以上就是Windows版本的环境搭建，接下来我们看看macOS的下的搭建也是目录我所在用的环境

#### macOS下环境搭建
mac环境下只要安装了Xcode就会自动帮安装上make工具，毕竟Xcode是世界上第二好用的IDE还是推荐安装的。如果实在觉得大可以去官方下载`Command Line Tools`也可以。官方没有编译好的适合mac二进制版本，在附加资料里我会提供适合macOS的二进制版本下载。我们放到`/opt/gbdk`下即可。


#### IDE的推荐
准备好编译环境我们再来准备一个写代码的IDE，这里推荐微软家的VSCode免费好用还跨平台。

### 第一个GB小程序

此段代码的功能可以在游戏界面上显示一个8x8像素的小人，并控制左右移动。
~~~ c
//引入GBDK头文件
#include <gb/gb.h>
//引入标准头文件
#include <stdio.h>

//精灵，之后课程会讲解精灵实现原理
unsigned char st[] =
{
  0x18,0x18,0x18,0x18,0x00,0x18,0x7E,0x7E,
  0x18,0x18,0x18,0x18,0x24,0x24,0x42,0x42
};

void main()
{
    //设置精灵数据
    set_sprite_data(0, 1, st);
    //设置精灵瓦块
    set_sprite_tile(0, 0);
    //移动到指定位置
    move_sprite(0, 20, 20);
    //调用显示精灵
    SHOW_SPRITES;
    while (1)
    {
        //根据操纵杆方向来控制精灵移动，目前还是一个初级的不带动画的移动，后续课程会讲解如何实现脚步动画
        if(joypad()==J_RIGHT)
        {
            scroll_sprite(0, 2, 0);
        }
        if(joypad()==J_LEFT)
        {
            scroll_sprite(0, -2, 0);
        }
        delay(50);
    }
    
}
~~~

将上诉文件保存为main.c,接下来我们创建一个Makefile文件
~~~ Makefile
//windows系统此行换为c:\tools\gbdk\bin\lcc -Wa-l -Wl-m -Wl-j
CC = /opt/gbdk/bin/lcc -Wa-l -Wl-m -Wl-j
BINS = main.gb

all:	$(BINS)

%.o:	%.c
	$(CC) -c -o $@ $<

%.gb:	%.o
	$(CC) -o $@ $^

clean:
    ///windows系统此行换为 `del /q  *.o *.lst *.map *.gb *~ *.rel *.cdb *.ihx *.lnk *.sym *.asm
	rm -f *.o *.lst *.map *.gb *~ *.rel *.cdb *.ihx *.lnk *.sym *.asm
~~~

以上两个文件保存在同一目录 后，执行`make`即可生成.gb文件。这是游戏机或模拟器所要使用的ROM文件。

![run demo](//blog.guohai.org/doc-pic/2020-01/demo.gif)

第一课就到这里我们只是搭建了构建环境，后续课程会进行详细的讲解。

### 参考资料
* [gbdk官网](http://gbdk.sourceforge.net/)
* [gbdk mac版本](http://static.guohai.org/gbdk-mac.zip)