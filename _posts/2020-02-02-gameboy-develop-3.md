---
layout: post
title:  "Gameboy游戏开发-精灵高阶"
date:   2020-02-04 04:02:02
categories: gameboy game develop
--- 
上节课聊到了精灵的反向问题，GB因为卡带容量的限制不可能每表方向都画，一般ACT类游戏只需要一个侧面，另一个方向时是通过瓦块的镜像的来实现的。我们使用的gbdk类库提供了一个`set_sprite_prop`方法看文档可以知道，改方法会接收一个8位的值，其中第5位为1时对应的精灵会做水平翻转。我们来看一下例子。

### 精灵的水平翻转
我们还是用上节课的例子来继续修改，我们的精灵当时做的是向右侧的。现在我们来修改一下当摇杆操作向左的时候进行镜像操作。
~~~ c
        else if(joypad()==J_LEFT)
        {
            set_sprite_tile(0, (run_index+4)*2);
            set_sprite_tile(1, (run_index+4)*2+2);

            //向左走时，水平镜像精灵。因为我们的角色是两个精灵拼合出来的，所以需要分别进行镜像。
            set_sprite_prop(0, S_FLIPX);
            set_sprite_prop(1, S_FLIPX);

            scroll_sprite(0, -2, 0);
            scroll_sprite(1, -2, 0);

            if(run_index==4)
            {
                run_index = 0;
            }
            else
            {
                run_index+=2;
            }
        }
~~~

运行看看效果，人物被镜像了。但.....恩对我们是原地镜像的。所以左右侧两个精灵没有调整位置。

![sprite_flipx](//blog.guohai.org/doc-pic/2020-02/sprite_flipx.png)

### GB游戏角色类

我们尝试封装一个游戏精灵类，默认是按16x16来支持，也就是同时支持两个瓦块。

首先我们新建一个 game_role.h 的头文件

~~~ c
#include <gb/gb.h>
#include <stdio.h>
/**
 * 游戏内角色的结构体,因为GB的机能限制，最大只支持8x16像素的sprit，
 * 因为我们每个角色使用32x32才能表示，所以一个数组来存储精灵的索引
 */
struct GameRole
{
    //精灵两个下标的存放数组
    UBYTE spritids[2];
    //精灵运动起来时的动画针索引
    UINT8 spritrun[3];
    //精灵的运动状态
    UINT8 spite_run_status;
    //精灵的x坐标
    UINT8 x;
    //精灵的y坐标
	UINT8 y;
    //精灵的面部朝向
    //1上，2右，3下，4左。我们这次只用左右和即可
    UINT8 direction;
};

//单个精灵瓦块的宽度
UINT8 sprite_size = 8;

/**
 * 移动精灵方法，我们要在.c文件中实现的
 */
void movegamecharacter(struct GameRole* character, UINT8 x, UINT8 y);
~~~

我们再新建一个类文件 game_role.c

~~~ c
#include "game_role.h"
/**
 * 移动精灵方法的实现
 */
void movegamecharacter(struct GameRole* character, UINT8 x, UINT8 y)
{
    //随着精灵的运动修改精灵的下标
    if(character->spite_run_status==2)
    {
        character->spite_run_status = 0;
    }
    else
    {
        character->spite_run_status++;
    }
    //运动状态时循环显示几个针的动画
    set_sprite_tile(character->spritids[0], character->spritrun[character->spite_run_status]);
    set_sprite_tile(character->spritids[1], character->spritrun[character->spite_run_status]+2);

    if(x<character->x && character->direction==2) {
        //向左移动
        set_sprite_prop(character->spritids[0],S_FLIPX);
        set_sprite_prop(character->spritids[1],S_FLIPX);
        character->direction = 4;
    }

    if(x>character->x && character->direction == 4) {
        //向右移动
        set_sprite_prop(character->spritids[0],!(S_FLIPX));
        set_sprite_prop(character->spritids[1],!(S_FLIPX));
        character->direction = 2;
    }
    //根据移动方向，移动精灵位置
    if(character->x!=x || character->y!=y) {
        if(character->direction ==2){
            move_sprite(character->spritids[0], x-4, y);
            move_sprite(character->spritids[1], x + sprite_size-4, y);
        }
        else if (character->direction == 4)
        {
            move_sprite(character->spritids[0], x, y);
            move_sprite(character->spritids[1], x - sprite_size, y);
        }
    }
}

~~~

接下来我们在主文件中引入此文件并重构下主文件，删除掉向左右移动时的代码。

~~~ c
#include <gb/gb.h>
#include <stdio.h>
#include "game_role.h"
#include "mario.c"

//定义角色
struct GameRole role;

/**
 * 新增加的方法，初始化角色
 */
void initRole(UINT8 x, UINT8 y) 
{
    role.x = 0;
    role.y = 0;
    role.spritrun[0] = 8;
    role.spritrun[1] = 12;
    role.spritrun[2] = 16;
    role.spite_run_status = 0;
    set_sprite_tile(0, role.spritrun[role.spite_run_status]);
    role.spritids[0] = 0;
    set_sprite_tile(1, role.spritrun[role.spite_run_status]+2);
    role.spritids[1] = 1;
    role.direction = 2;
    movegamecharacter(&role,x,y);
    role.x = x;
    role.y = y;
}

/**
 * 新的mian方法
 */
void main()
{
    SPRITES_8x16;
    set_sprite_data(0, 20, mario);
    initRole(28,112);
    SHOW_SPRITES;
    while (1)
    {
        if(joypad()==J_RIGHT)
        {
            movegamecharacter(&role,role.x+2,role.y);
            role.x +=2;
            
        }
        else if(joypad()==J_LEFT)
        {
            movegamecharacter(&role,role.x-2,role.y);
            role.x -= 2 ;
        }
        else 
        {
            set_sprite_tile(0, 0);
            set_sprite_tile(1, 2);
        }
        delay(80);
    }
    
}

~~~

这会咱们的main方法重构完更简洁了。因为我们增加了一个类文件进来，在make前，我们还要修改下Makefile文件。

~~~ Makefile
CC = /opt/gbdk/bin/lcc -Wa-l -Wl-m -Wl-j
BINS = main.gb

all:	$(BINS)

%.o:	%.c
	$(CC) -c -o $@ $<

%.gb:	main.o game_role.o
	$(CC) -o $@ $^

clean:
	rm -f *.o *.lst *.map *.gb *~ *.rel *.cdb *.ihx *.lnk *.sym *.asm
~~~

`make` 运行。

![mario](//blog.guohai.org/doc-pic/2020-02/ezgif-2-db476b78d9c8.gif)

原计划本课还会讲到调色板，但因为咱们重构了一下角色类。内容有点多，怕吸收不好，调色板的内容我向后移动了。