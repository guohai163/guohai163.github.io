---
layout: post
title:  "Gameboy游戏开发⑦-敌人板栗仔"
date:   2020-03-16 10:02:02
categories: [develop, gameboy]
tags: [game, develop, gbdk]
image: /doc-pic/2020-03/super-mario-block.jpg
---
咱们的课程已经进行到了第7课我把之前的代码放到了单独的仓库里，项目起名为[Hashiru](https://github.com/guohai163/hashiru)。每一课我都打了一个标签，大家可以分别获取回来

## 会穿透的板栗仔
本课开始，首先要下手的就是在GBTD里画出板栗仔，板栗仔的大小是16x16像素也就是4个瓦块。头部是左右对称的，脚部是不对称的，之后我们可以反复使用镜像方法，让板栗仔动起来。

![goomba.png](/doc-pic/2020-03/goomba.png)

因为我们的板栗移动方法与主角不一样，只需要横向，从右向左移动即可，所以我们在game_role文件中增加一个`checkcollisions`方法：

~~~ c
/**
 * 障碍物的移动
 */
void movegameobstacle(struct GameRole* character, UINT8 x, UINT8 y)
{
    // 反复交替板栗仔的左右朝向，让板栗仔有一种左右踏脚的感觉
    if(character->direction == 2)
    {
        set_sprite_prop(character->spritids[0], get_sprite_prop(character->spritids[0]) | S_FLIPX);
        set_sprite_prop(character->spritids[1], get_sprite_prop(character->spritids[1]) | S_FLIPX);
        character->direction = 4;
    }
    else
    {
        set_sprite_prop(character->spritids[0],get_sprite_prop(character->spritids[0]) & 0xdfu);
        set_sprite_prop(character->spritids[1],get_sprite_prop(character->spritids[1]) & 0xdfu);
        character->direction = 2;
    }
    // 镜像后需要交替左右两个半截的位置
    if(character->direction ==2){
        move_sprite(character->spritids[0], x , y);
        move_sprite(character->spritids[1], x + sprite_size, y);
    }
    else if (character->direction == 4)
    {
        move_sprite(character->spritids[0], x+sprite_size, y);
        move_sprite(character->spritids[1], x , y);
    }

}
~~~

接下来我们打开main.c主程序：

~~~ c
//首先在文件头部增加板栗对象
struct GameRole goomba;

/**
 * 定义一个初始化板栗仔的方法
 */
void initGoomba(UINT8 x, UINT8 y)
{
    goomba.x = 0;
    goomba.y = 0;
    goomba.width = 10;
    goomba.height = 16;
    goomba.spritrun[0] = 20;
    goomba.spite_run_status = 0;
    goomba.spritids[0] = 2;
    goomba.spritids[1] = 3;
    set_sprite_tile(goomba.spritids[0], goomba.spritrun[goomba.spite_run_status]);
    set_sprite_tile(goomba.spritids[1], goomba.spritrun[goomba.spite_run_status]+2);
    movegameobstacle(&goomba,x,y);
    set_sprite_prop(2,2);
    set_sprite_prop(3,2);
    goomba.x = x;
    goomba.y = y;
    goomba.direction = 2;
}

void main()
{
    // 接下来在主函数中调用初始化方法
    initGoomba(180, 112);
    ...
    while(1)
    {
        // 并在while循环中让板栗仔自动开始移动
        movegameobstacle(&goomba, goomba.x-2, goomba.y);
        goomba.x -=2 ;
        ...
    }

}
~~~
我们来第一次`make run`，额这应该不是大家想要的吧，为什么板栗仔穿透了？

![goomba-1.gif](/doc-pic/2020-03/goomba-1.gif)

## 能够杀死主角的了板栗仔
因为缺少碰撞检测，所以板栗仔穿透了过去。要进行碰撞我们要先标记出精灵的大小，我们在Gamerole结构体里增加一个width和一个height属性。并在初始化精灵时设置精灵的大小，为了更好的体验，我们把精灵的高设置为16，宽设置为10。再来看一下碰撞实现：

~~~ c
/**
 * 碰撞检查函数,实现原理是检测两个精灵是否有重叠部分
 */
UBYTE checkcollisions(struct GameRole* one, struct GameRole* two)
{
    return (one->x >= two->x && one->x <= two->x + two->width) && (one->y >= two->y && one->y <= two->y + two->height) || (two->x >= one->x && two->x <= one->x + one->width) && (two->y >= one->y && two->y <= one->y + one->height);
}

// 修改main方法
void main()
{
    ...
    while(!checkcollisions(&role, &goomba))
    {
        ...
    }
    //当碰撞后我们结束游戏，并输出game over
    printf("\n \n \n \n \n \n \n === GAME  OVER ===");
}
~~~
`make run`

![goomba-2.gif](/doc-pic/2020-03/goomba-2.gif)

主角就这么被杀了，不会跳怎么办？下节课我们会来讲精灵的跳跃方法。
