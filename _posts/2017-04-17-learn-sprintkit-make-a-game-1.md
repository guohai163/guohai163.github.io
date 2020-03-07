---
layout: post
title: "学习SpriteKit开发（1）"
date: 2017-04-17 14:00
categories: [develop, game]
tags: [swift, spritekit, game, developer, xcode, iOS]
---
开发一款单机RPG游戏是很多80后儿时的梦想，但因为盗版等原因，国内的PC、家用机单击市场已经彻底被毁掉。新的独立游戏人想在这两个平台上线已经非常困难，引擎学习成本偏高。机能强大更多的强调的是游戏界面而不仅仅是游戏情节。但手机市场就大不同，机能还不够强大基本等于SFC、N64这个水准，吸引用户更多的还要依靠玩法和剧情。

本教程会基于swift3.0语言使用spritekit框架来进行讲解，会涉及到碰撞、纹理管理、互动、音效、按钮、场景、马赛克拼图、自制虚拟摇杆、AppleGameCenter接入、内购流程。基本教程游戏是一款横版射击游戏。学习前请先看一下苹果的官方文档 [SpriteKit](https://developer.apple.com/spritekit/)

先看一下第一课今天的最终学习成果
![fighter.gif](http://guohai163.github.io/doc-pic/2017-04-17-spritekit/fighter.gif)

### 开始 ###
准备工作，首先得有一台装有xcode8以上的macOS机器，SpriteKit框架相对于其它的引擎来说最大优点就是官方原生支持。
选择创建项目，语言选择swift,游戏引擎选择SpriteKit即可。
创建好的DEMO项目默认长这样。

![null project](http://guohai163.github.io/doc-pic/2017-04-17-spritekit/nullproject.png)

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
说到操控，触屏手机第一想到的就是直接点击控制小飞机的飞行方位。但第一版试验后不是很理想，手指头会挡住部分画面，以及部分飞过来的子弹。这里我们来模拟个遥感，使用虚拟摇杆操控飞机。

关于摇杆的实现我参考了 叶流月 的[一篇文章](http://www.jianshu.com/p/c108372d5adb)，

首先创建我们的遥控器类 MoveConSpriteNode.swift 首先我们创建两个圆
``` swift3
//实心圆
private var movePoint : SKShapeNode = SKShapeNode(circleOfRadius: 10)
//大空心
private var moveController = SKShapeNode(rectOf: CGSize(width:106, height:106), cornerRadius: 53)

public func setup() {
    //实心
    movePoint.fillColor = SKColor(red: 1, green: 1, blue: 1, alpha: 0.8)
    movePoint.position = CGPoint(x: 70, y: 70)
    addChild(movePoint)

    moveController.lineWidth = 2
    moveController.position = CGPoint(x: 70, y: 70)
    addChild(moveController)
}
```
然后我们来处理touchesBegang事件
``` swfit3
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    DLLog(message: "控制器被按下")
    for t in touches {
        isMoveTouch = true
        //取出按下坐标
        let position  = t.location(in: self)
        let x1 = position.x - 70
        let y1 = position.y - 70
        //计算是否在摇杆内,如果不在直接退出
        if abs(x1)<=15 && abs(y1)<=15 {
            return
        }
        if abs(x1) >= 35 && abs(y1) >= 35 {
            isMoveTouch = false
            return
        }

        var ys:CGFloat
        var xs:CGFloat
        if x1*x1 + y1*y1 > 2500 {
            let z = x1 / y1
            let temp = 2500 / (1+z*z)
            ys = sqrt(temp)
            xs = abs(ys * z)
            if y1 < 0 {
                ys = ys * -1
            }
            if x1 < 0 {
                xs = -xs
            }
            let newPoi = CGPoint(x: 70 + xs, y: 70 + ys)
            movePoint.position = newPoi
        } else {
            let newPoi = CGPoint(x: 70 + x1, y: 70 + y1)
            movePoint.position = newPoi
        }

    }
}
```
最后我们增加一个 公有方法返回控制点偏移量
``` swift3
//返回控制点相对偏移量
public func MovePosition() -> CGPoint {
    return CGPoint(x: movePoint.position.x - 70, y: movePoint.position.y - 70)

}
```

回到我们的游戏主场景 增加相应的 `touchesBegan touchesMoved touchesEnded` 三个方法的转发操作。

运行试一下，摇杆已经可以感应手指的操作了。最后的最后，我们来让小飞机也听我们的控制,增加一个update方法
``` swfit3
override func update(_ currentTime: TimeInterval) {
    //获取摇杆偏移量
    let poi = moveCon.MovePosition()
    //增加小飞机动画飞往目标位置
    let moveAction = SKAction.move(to: CGPoint(x: fighterNode.position.x + poi.x,y: fighterNode.position.y + poi.y), duration: 0.1)
    fighterNode.run(moveAction)    
}
```
运行起来试试，糟糕我的小飞机飞出屏幕找不到了，这个留给大家来想办法吧。今天的文档先到这里。明天[下一次]我们会增加一些陨石碎片。

完整源码请访问 [https://github.com/guohai163/Fighter4iOS](https://github.com/guohai163/Fighter4iOS)
