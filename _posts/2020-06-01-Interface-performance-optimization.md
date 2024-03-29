---
layout: post
title:  "记录一次性能HTTPS站点的性能调优过程"
date:   2020-06-01 06:01:00
categories: [develop]
tags: [raml, rest, test]
image: /doc-pic/2020-06/tls-1.3-handshake-performance.png
---

最近支付宝小程序允许个人开发者上架应用了。我也很快的改写了我的《疫苗批号查询》程序，顺利过审上架。并且明显能看到阿里虽然在各个方面都是在抄袭微信小程序，但无论是IDE还是管理后台都更上了一个层级。这不昨天我的小程序上架满一周评级出来了，B级看了下健康问题主要是首屏开启过慢部分用户会超过3000ms。

![queryvaccine_scron](/doc-pic/2020-06/queryvaccine_scron.png)

为了让评级继续上升，让用户有更好的体验。我得优化我的程序，首先画个流程图看一下。首先小程序启动时会进去App内的onLaunch方法，从小程序缓存中加载用户数据并存储在全局变量中。接下来进入首屏中的onLoad方法，如果上一步加载用户信息失败，证明是首次启用需要进行静默授权，并将用户授权ID交给服务器换取用户唯一编号【这步理论上应该不是必须在加载界面前做的之后会移到onReady方法中】。第三步请求服务器获得最新数据的时间点并显示在界面上，因为影响界面内容还是会保留在onLoad方法，初步判断这步服务器端程序查询完会放到一个静态变更中，之后再次查询直接返回静态变量的结果，理论上不应该会有性能问题。

![aliapp-firestart](/doc-pic/2020-06/aliapp-firestart.png)

开始进行方法位置的调整，把用户静默授权从onLoad方法中迁移走，不再影响首屏渲染。调整后再次使用ide的性能调试工具进行测试，首屏启动有明显的改善。使用云真机进行测试，发现还是有部分手机首屏加载超过3000ms。目前就只剩下获取最后更新时间的一个网络请求方法了。使用postman进行测试改方法延时300~500ms左右。

看服务器代码方法就是查数据库返回一个值，而且首次查询后就会放到静态变量中。此时怀疑会不会因为是私有的静态变量，类被回收时变量也被回收了。加日志跑了几个小时验证变量只要启动就没有被回收过。看来问题不是出在这里。下一步我们打开服务器的远程调试看看是不是真的是性能问题。

~~~ java
    /**
     * 最后更新时间
     */
    private static String lastDate="";
    public Result<String> getLastDate() {
        if("".equals(lastDate)){
            lastDate=vaccineDao.getLastDate();
        }
        return new Result<>(true,lastDate);
    }
~~~

### 压测开始

接下来我们使用JMeter开始进行压测，看监控可以看到堆内存在不停的申请释放，初步怀疑是堆内存给的太小。另外模拟100个用户压测压测开始服务器需要创建大量的线程会有CPU开销。开始了如下的折腾：

1. 因为模拟100个用户同时请求，服务器会新起大量的线程来应付连接。修改yml文件，让默认启动线程改到20个起，上限为100。再次压测可以看到初步解决了线程申请的开销
2. 打印GC日志。发现默认配置使用的还是古老的Serial垃圾收集器，缺点就是“垃圾回收速度较慢且回收能力有限，频繁的STW会导致较差的使用体验”。我们修改启动参数，增加-XX:+UseG1GC参数使用现代的G1垃圾收集器。并增大堆内存的起始大小，再进行压测打印GC日志发现回收频率明显降低。

重新进行压测依然是300~800ms左右延迟情况。到此时我觉得java程序上已经没有可优化的部分了，我开启了nginx的缓存机制。把此接口的结果进行了24小时的缓存，再进行压测。我艹折腾了一天了结果居然还是首次请求需要耗时800ms左右的这么一个曲线。

![10921591082311.jpg](/doc-pic/2020-06/10921591082311.jpg)

### 重新开始排查

上了nginx缓存后已经可以完全排除是Java程序的性能问题了，我开始从服务器上找原因了。首先想到了是我图便宜使用的是阿里云的突发性能实例。这种实例的特点就是你每分钟都会得到CPU使用积分，当你使用CPU超过一个阈值时会开始消耗CPU积分，当CPU积分消耗完时你就无法得到CPU资源。但是，我去看了下控制台，从压测开始到结果都没达到能扣CPU积分的情况。证明此处并没有太多的消耗。

接下来我启用了抓包大法，Wireshark。我们先抓一个标准HTTP请求的包

![httpget](/doc-pic/2020-06/httpget.png)
可以看到整个过程就是三次TCP握手，然后就开始发送http请求以及应答，整个过程只需要17ms就结束了。

我们再来看看HTTPS的请求过程，我们使用TLSv1.2版本协议。先是标准的tcp三次握手，然后就开始了数个来回的tls证书交换过程，第33ms时才开始正式的发起get请求。在我们网络比较良好的情况下还消耗了40ms。多次测试发现一旦网络不好就会向几百ms飘去。

![https](/doc-pic/2020-06/httpsget.png)

### 结案以及解决方案

此案基本解决，主要问题还是发生在tls1.2协议版本上。可以看到1.3版本大大的优化了握手的过程，但1.3版本对浏览器的支持也是很惨的。只有很少的浏览器能够支持。

另一个靠谱的解决方案就是修改程序业务逻辑，减少首屏时的网络请求，甚至比如我的应用场景里也可以避免并置后。

### 广告时间

![s6x12697xa4kejzvpw3bv22_140614148.jpg](/doc-pic/2020-06/s6x12697xa4kejzvpw3bv22_140614148.jpg)
一个不正经的小程序，设计初衷是方便父母查询婴儿疫苗审批情况验证合格与否。上线后每天数千的妙龄少女来使用，我以为是国民提前进入育儿年龄了。结果发现居然被少女们用来查这个

![IMG_0242.PNG](/doc-pic/2020-06/IMG_0242.PNG)

### 参考资料

* [Java垃圾收集器——Serial，Parallel，CMS，G1收集器概述](https://www.lagou.com/lgeduarticle/51284.html)
* [TLS 1.2 VS 1.3](https://www.jianshu.com/p/efe44d4a7501)
* [VisualVM用于查看运行中的Java应用程序的详细信息](https://visualvm.github.io/)
* [Wireshark免费开源的网络数据包分析软件](https://www.wireshark.org/)