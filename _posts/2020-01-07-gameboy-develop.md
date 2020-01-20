---
layout: post
title:  "Gameboy游戏开发"
date:   2020-1-1 1:1:1
categories: gameboy game develop
---

Gameboy是80、90后童年曾经陪伴过的掌上游戏机，给我们儿时带来了很多欢乐。我还记得我的GB是96年时用压岁钱买的，当时从父母那里收了200的压岁钱，自己用平时积攒的200块钱自己坐了2个小时的车去了大城市锦州买的这台游戏机。当时已经没有钱再买游戏卡了，还是从我们这叫老六那租的游戏卡一块钱一天。当时也想好奇过GB上的游戏是怎么做出来的？好奇归好奇那个年代信息闭塞不太可能知道答案。

![gameboy picture](//blog.guohai.org/doc-pic/2020-01/oldgb.jpg)

今天互联网发达了，我儿时的梦想也算可以实现了。GB的原生开发都是使用汇编语言操作z80CPU，但汇编的学习曲线有点长，网上有人做了个c语言的封装类库。虽然执行效率要比汇编差点，但我们又不做太大型的游戏不会出现太大的差别。

### 机器介绍
要想做好游戏得先了解一下游戏机的基本性能。这里的GB只包含 第一代厚Gameboy,第二代超薄Gameboy Pocket,第三代最短暂的Gameboy Light,第四代Gameboy Color。再往后的GBA并不包含在内。CPU全系列均为z80cpu，只是不同的GB频率有区别。屏幕分辨率160x144像素，背景或窗体块大小8x8像素，对象/精灵块大小可以是8x8或

![gameboy layer](//blog.guohai.org/doc-pic/2020-01/gb_layer.png)