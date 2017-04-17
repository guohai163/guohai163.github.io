---
layout: post
title: "学习SpriteKit开发（1）"
date: 2017-04-17 14:00
categories: swift spritekit game developer xcode iOS
---
开发一款单机RPG游戏是很多80后儿时的梦想，但因为盗版等原因，国内的PC、家用机单击市场已经彻底被毁掉。新的独立游戏人想在这两个平台上线已经非常困难，引擎学习成本偏高。机能强大更多的强调的是游戏界面而不仅仅是游戏情节。但手机市场就大不同，机能还不够强大基本等于SFC、N64这个水准，吸引用户更多的还要依靠玩法和剧情。

本教程会基于swift3.0语言使用spritekit框架来进行讲解，会涉及到碰撞、纹理管理、互动、音效、按钮、场景、马赛克拼图、自制虚拟摇杆、AppleGameCenter接入、内购流程。基本教程游戏是一款横版射击游戏。学习前请先看一下苹果的官方文档 [SpriteKit](https://developer.apple.com/spritekit/)

### 开始 ###
准备工作，首先得有一台装有xcode8以上的macOS机器，SpriteKit框架相对于其它的引擎来说最大优点就是官方原生支持。
选择创建项目，语言选择swift,游戏引擎选择SpriteKit即可。
创建好的DEMO项目默认长这样。![null project](http://guohai163.github.io/doc-pic/2017-04-17-spritekit/nullproject.png)
` command+r `运行你的项目吧。DEMO项目中的场景使用的是sks，这里我们先不做分析直接删除，我们从代码开始学习。
删除整理后的代码差不多是这个样子，Support主要放辅助类文件，scenes下放几个场景类，Sprites是核心，所有的精灵类都会放到这里。
![init project](http://guohai163.github.io/doc-pic/2017-04-17-spritekit/initproject.png)

### 让飞机从屏幕中出现 ###
首先修改我们的GameViewController类，把加载GameScene.sks修改为加载GameScenes.swift类文件
``` swift3
// Load the SKScene from 'GameScene.sks'
if let scene = SKScene(fileNamed: "GameScene") {

    // Present the scene
    view.presentScene(scene)
}
///修改为
// Load the SKScene from class
let scene : SKScene = GameScene(size: view.frame.size)


// Present the scene
view.presentScene(scene)
//同时我们打开显示 物理特性标记方便调试

view.showsPhysics = true
```
首先我们来初始化下背景，在Sprites组下创建一个背景Node类 BackgroundNode.swift 。目前我们只设置一个天空，后期会利用这个类让天空动起来
``` swift3
import SpriteKit

class BackgroundNode : SKNode {

    public func setup (size : CGSize) {

        //创建一个天空
        let skyNode = SKShapeNode(rect: CGRect(origin: CGPoint(), size: size))
        //百科了下，这个RGB值就是天蓝色，暂时先这样了
        skyNode.fillColor = SKColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        skyNode.strokeColor = SKColor.clear
        skyNode.zPosition = 0

        addChild(skyNode)
    }
}
```
把我们新做好的天空背景加入到我们的场景里,回到主场景 GameScene.swift类里增加覆写的sceneDidLoad方法。
``` swift3
private let backgroundNode = BackgroundNode()


override func sceneDidLoad() {


    //加入背景NODE
    backgroundNode.setup(size: size)
    addChild(backgroundNode)
}
```
再次启动应用，界面已经全蓝，我们让小飞机加起来吧。找到一个小飞机素材，放到Assets.xcassets下。结果会像这个样子![we fighter](http://guohai163.github.io/doc-pic/2017-04-17-spritekit/fighterstyle.png)

新建一个战斗机类 FighterSpriteNode.swift
``` swift3
import SpriteKit

class FighterSpriteNode : SKSpriteNode {

    //因为我们的主角只有一个，所以 我们来一个单例模式
    public static func newInstance() -> FighterSpriteNode {
        //通过图片的方法加载我们的主角
        let fighter = FighterSpriteNode(imageNamed: "fighter")

        return fighter
    }
}
```
接下来，我们会在 GameScene场景中新建一个spawnFighter方法来复用我们的战斗机，同时保证在同一场景中我们的主角只有一个。
在这里要讲一下SpriteKit的坐标系是左下角为原点，开始进行计算
``` swift3
private func spawnFighter() {
    //初始化我们的小飞机
    fighterNode = FighterSpriteNode.newInstance()
    //决定我们飞机的位置 ，左屏幕右侧出现
    fighterNode.position = CGPoint(x: 100, y: size.height/2)

    addChild(fighterNode)
}
```
在我们的sceneDidLoad合适的位置 调用 spawnFighter方法，运行程序，我们的小飞机已经出现在我们的手机界面上了。
![fighteratios.png](http://guohai163.github.io/doc-pic/2017-04-17-spritekit/fighteratios.png)
🤦‍♂️这比例，有够惨，但为了看的清楚，我们先这样了
### 操控小飞机移动 ###
