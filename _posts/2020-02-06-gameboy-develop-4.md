---
layout: post
title:  "Gameboy游戏开发-调色板"
date:   2020-02-06 10:02:02
categories: gameboy game develop
--- 
首先我们先看看如何告诉模拟器或真机，这个ROM是个纯GB卡还是GBC卡。查了一下文档需要在ROM的0x143这个地址修改为0x80。gbdk的修改方法是在链接目标文件到gbROM的时候增加参数`-Wl-yp0x143=0x80`，至于到我们的项目上需要修改Makefile文件。看一下修改后的文件内容
~~~ makefile
CC = /opt/gbdk/bin/lcc -Wa-l -Wl-m -Wl-j
BINS = main.gb

all:	$(BINS)

%.o:	%.c
	$(CC) -c -o $@ $<

%.gb:	main.o game_role.o
	$(CC) -Wl-yp0x143=0x80 -o $@ $^

clean:
	rm -f *.o *.lst *.map *.gb *~ *.rel *.cdb *.ihx *.lnk *.sym *.asm
~~~

我们在第10行上增加了相应的指令。我们用模拟器跑起来看一下效果

![cgb-mgc](//blog.guohai.org/doc-pic/2020-02/dmg-cgb.png)

运行起来左侧的图是没加标记的，可以看到模拟器按GB卡带进行了识别使用了绿色。而右侧的正确识别成了GBC卡带，背景色已经是白色了。我们的mario还被随机图了一个颜色。

### 输出自定义颜色的类文件
重新使用我们的gbtd打开mario.gbr文件，选择`View->Color set->Gameboy Color`模式。选择后Paletees变为可点击，可以给我们的马里奥几套上色方案。

![palete](//blog.guohai.org/doc-pic/2020-02/gbtd-palettes.png)

其中下标为0的是默认配色，从下标1开始是我们自定义的配合。这里要注意在GB内背景每个瓦块可以有4种颜色，精灵每个瓦块最多就只有3种颜色了，颜色0会透明化。接下来我们重新导出mario.c和.h文件。导出的时候需要打开高级下的导出调色版的勾。我们主要使用CGB模式，我们在CGB模式上选择为`1 Byte per entry`

![export-palettes](//blog.guohai.org/doc-pic/2020-02/export-palettes.png)

我们看看导出的.h文件里多了些什么信息，可以看到调色板1、2都已经是我们自定义的颜色了。下面咱们来开始修改程序部分。
~~~ c
/* Gameboy Color palette 0 */
#define marioCGBPal0c0 6076
#define marioCGBPal0c1 8935
#define marioCGBPal0c2 6596
#define marioCGBPal0c3 5344

/* Gameboy Color palette 1 */
#define marioCGBPal1c0 6076
#define marioCGBPal1c1 2783
#define marioCGBPal1c2 6574
#define marioCGBPal1c3 27

/* Gameboy Color palette 2 */
#define marioCGBPal2c0 6076
#define marioCGBPal2c1 2783
#define marioCGBPal2c2 6574
#define marioCGBPal2c3 704
~~~

### 为我们的人物上色
先看一下我们需要用到的两个函数，`void 	set_sprite_palette (UINT8 first_palette, UINT8 nb_palettes, UINT16 *rgb_data)` 该方法可以把我们的配置好的调色板方案加载到内存中，第三个参数是要加载的数组，第一个参数是数组的的起始位置，第二个参数是要加载的大小。第二个方法`void set_sprite_prop (UINT8 nb, UINT8 prop)`在上一节课的精灵翻转时就有用过，但没有细讲第二参数的具体含义。第二参数是一个复合属性。我们来看一下表格：

|  位   | 7  | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|  ----  | ----  |----  |----  |----  |----  |----  |----  |
| 特性  | 相对于背景 | Y轴翻转 | X轴翻转 | DMG调色板 | GBC 块切换 | 颜色 | 颜色 | 颜色 |
| 0  | 在前 | 不翻转 | 不翻转 | 单色调色板0 | 使用块0 | 0 | 0 | 0 | 
| 1 | 在后 | 进行翻转 | 进行翻转 | 单色调色板1 | 使用块1 | 1 | 1 | 1 |

上一节课我们用的是第5位按X轴翻转，这次我们要用的是低三位。通过计算我们可以知道3位最多能表示8种颜色，这也是为什么在GBTD里我们只能配置8种调色方案。现在我们来看一下具体的实现方案。我们继续在之前课程的基础上进行修改。我省略了之前课程的代码，更全的代码我会放在课程结尾。
~~~ c
//首先我们创建set_sprite_palette方法要用到的数组
const UWORD spritepalette[] = {
    marioCGBPal1c0,
    marioCGBPal1c1,
    marioCGBPal1c2,
    marioCGBPal1c3
};
void initRole(UINT8 x, UINT8 y) 
{
    //TODO 省略部分代码
    //设置精灵使用
    set_sprite_prop(0,0x00u);
    set_sprite_prop(1,0x00u);
}
void mian()
{
    //TODO 省略部分代码
    //引入调色板数据
    set_sprite_palette(0, 1, spritepalette);
}
~~~
打开我们的game_role.c文件，将之前的set_sprite_prop方法进行一下修改
~~~ c
    if(x<character->x && character->direction==2) {
        //向左移动
        set_sprite_prop(character->spritids[0], get_sprite_prop(character->spritids[0]) | 0x20u);
        set_sprite_prop(character->spritids[1], get_sprite_prop(character->spritids[1]) | 0x20u);
        character->direction = 4;
    }

    if(x>character->x && character->direction == 4) {
        //向右移动
        set_sprite_prop(character->spritids[0],get_sprite_prop(character->spritids[0]) & 0xdfu);
        set_sprite_prop(character->spritids[1],get_sprite_prop(character->spritids[1]) & 0xdfu);
        character->direction = 2;
    }
~~~

`make`来重新编译运行我们的项目。DEMO中还实现了马里奥大叔的无敌功能，大家考虑下如何实现？

![mario-color.gif](//blog.guohai.org/doc-pic/2020-02/mario-color.gif)


### 资料
* [源码下载](//blog.guohai.org/doc-pic/2020-02/gb4.zip)


---

如果觉得文章内容比较实用，获得后续更新通知请关注公众号：

![guohaiqr.jpg](//blog.guohai.org/doc-pic/guohaiqr.jpg)