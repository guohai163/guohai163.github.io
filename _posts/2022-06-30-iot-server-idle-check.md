---
layout: post
title:  "物联网的服务端设计(三)"
date:   2022-06-30 10:10:00
categories: [develop]
tags: [iot, java, netty]
image: /doc-pic/2022/iot.svg
---

## 会话管理

这次我们要搞的是给咱们的iot服务端增加一个会话管理，并定时打印一个关于连接情况的报表。创建一个会话管理类 SessionManager。
首先我们创建两个Map对象，分别用来存储以channel为key的会话信息，和以devid为key的channel对象。第一个sessions对象主要是接收数据时可以通过chnanel找到具体的设备信息，
第二个channels对象是供下行数据包时可以通过设备ID查找到对应的channel对象。

这里还要考虑一个Map的实现类的问题，如果你的SessionInfo是大量不可变数据，比如连接后就不再进行变动就用HashMap实现就行。如果你的SessionInfo会存储大量需要变更的数据，比如每次上报都要变更
请使用ConcurrentHashMap来初始化。防止在多线程高并发操作时有脏数据的出现。另外HashMap的默认空间为16，当达到75%这个阈值时就会开始进行一次扩容。为了防止Map频繁扩容初始化时就要指定一个大小
大小为预估的你单服务器可承载客户端数量。

~~~ java 
    /**
     * 当前服务器预估的最大连接数
     */
    private static final int SERVER_CONNECT_NUM = 5000;

    /**
     * 存储会话,为了防止使用map时进行动态扩容，初始化时直接指定一个预估的单服务器连接数
     */
    private final Map<Channel, SessionInfo> sessions = new HashMap<>(SERVER_CONNECT_NUM);

    /**
     * 存储管道
     */
    private final Map<String, Channel> channels = new HashMap<>(SERVER_CONNECT_NUM);
~~~

接下来增加两个比较简单的成员方法，addSession和removeSession。这里我们增加了一个设置，当终端连接上来就会增加session，当终端发送login数据包时再补全session和增加channel对象。
这样做的好处是可以通过使用session内的数据填充情况发现连接上来但不发登录包的终端。可以踢掉这样的终端防止恶意占用服务端连接数。

~~~ java
    /**
     * 增加会话，当终端连接上来就进行注册。
     * 终端发送login包时再更新会话属性
     * @param channel 通道
     */
    public void addSession(Channel channel) {
        SessionInfo session = new SessionInfo();
        session.setChannel(channel);
        sessions.put(channel, session);
    }

    /**
     * 终端登录后补充会话信息,现时增加channel
     * @param channel channel
     * @param devId 设备ID
     * @param version 设备版本
     */
    public void setSession(Channel channel, String devId, String version){
        SessionInfo session = sessions.get(channel);
        session.setVersion(version);
        session.setDevId(devId);

        channels.put(devId, channel);
    }	

	/**
     * 移除会话，当终端断开时请求
     * @param channel channel
     */
    public void removeSession(Channel channel) {

        SessionInfo sessionInfo = this.getSession(channel);
        if(sessionInfo != null) {
            if(sessionInfo.getDevId() != null && !sessionInfo.getDevId().isEmpty()) {
                // 如果设备已经登录过，还需要同时移除channel
                sessions.remove(channel);
                channels.remove(sessionInfo.getDevId());
            } else {
                sessions.remove(channel);
            }
        }
    }
~~~

在回来解码器，准备处理发现连接时调用 addSession 方法前，还得考虑个问题。我们需要在 DecoderHandler 中使用 SessionManager 最简单的方式是 @Autowired。让Spring来帮我们管理，
但netty要求ChannelHandler是每个线程一份的，就算指定bean的scope是原型也无效。这里有三种解决方案

1. 每次都是new的，但把需要依赖spring完成初始化的传参进去
2. 使用一个ApplicationContextHolder工具类，在handler中通过applicationContext.getBean来获取
3. 如果能保证线程安全的情况下 给ChannelHandler增加@Sharable注解

DecoderHandler 中我们采用第一种方案，后续的会话打印我们用第三种方案。

在 DecoderHandler 中我们覆写一下 channelRegistered 方法，当有新请求上来时会调用该方法。并在改方法内优化一下 ChannelConfig 
~~~ java
    /**
     * 构造方法用来接收 sessionManager 对象
     * @param sessionManager 会话管理
     */
    public DecoderHandler(SessionManager sessionManager){
        this.sessionManager = sessionManager;
    }

    /**
     * 当有客户端注册时调用
     * @param ctx ChannelHandlerContext
     */
    @Override
    public void channelRegistered(ChannelHandlerContext ctx) throws Exception {
        ChannelConfig config = ctx.channel().config();
        DefaultSocketChannelConfig socketConfig = (DefaultSocketChannelConfig)config;
        // 此处三个参数决定 延迟情况
        // 连接时间 、往返延迟、 带宽。
        // 这三个参数设置的是权重
        // 因为我的连接会保持住 长连接不会频繁断开，所以 把连接时间权限设置的最低为0
        // 因为我们对往返延迟有一些容忍度，所以 第二参数是1
        // 对于带宽我们会有更大的需求，第三个参数设置为2 这就是目前的权重比
        // 延迟和带宽的性能是互斥的 , 延迟低 , 就意味着很小的包就要发送一次 , 其带宽就低了 , 延迟高了 , 每次积累很多数据才发送 , 其带宽就相应的提高了
        socketConfig.setPerformancePreferences(0,1,2);
        // NioSocketChannel在工作过程中，使用PooledByteBufAllocator来分配内存
        socketConfig.setAllocator(PooledByteBufAllocator.DEFAULT);
        super.channelRegistered(ctx);

        // 增加会话
        sessionManager.addSession(ctx.channel());
    }
~~~

## 打印会话状态

接下来我用准备让服务端帮我们定时输出这样的一个报表。

~~~ shell
+---------+---------+----------------+---------------+
| session | channel | main disruptor | log disruptor |
+---------+---------+----------------+---------------+
|       2 |       0 |              0 |             0 |
+---------+---------+----------------+---------------+
~~~
EventLoop是事件循环对象实现了定时线程池的接口我们可以让我们的workerGroup组来帮我们做这件事。我们新建一个StatusPringHandler 类并实现Runnable接口中的run方法。
~~~ java
@Override
public void run() {
    logger.info(
        "+---------+---------+----------------+---------------+\n" +
        "| session | channel | main disruptor | log disruptor |\n" +
        "+---------+---------+----------------+---------------+\n"+
        "| "+String.format("%7d",sessionCount)+" | "+String.format("%7d",channelCount)+" |        "+String.format("%7d",mainDis)+" |       "+String.format("%7d",logDis)+" |\n"+
        "+---------+---------+----------------+---------------+\n");
    }
~~~

加到主方法里，给workerGroup增加一个定时器

~~~ java
// 为worker组设置一个定时器,其中参数2为首次调用等待，参数3为之后每次调用间隔等待，参数4是时间单位
workerGroup.next().scheduleAtFixedRate(statusPringHandler,1, 60, TimeUnit.SECONDS);
~~~

## 空闲检测

在TCP的机制里面，本身是存在有心跳包的机制的，也就是TCP的选项：SO_KEEPALIVE。系统默认是设置的2小时的心跳频率。但是它检查不到机器断电、网线拔出、防火墙这些断线。我们还需要在业务层定时检测客户端是否有自定的数据包，如没有可能终端掉线，需要踢掉防止占用连接。

看下我们的 IdleCheckHandler 类，需要覆写下 ChannelDuplexHandler 的 userEventTriggered 方法：

~~~ java
/**
 * 空闲检测器
 * 如果增加@Sharable注解，该类必须是线程安全的
 * @author guohai
 */
@Component
@ChannelHandler.Sharable
public class IdleCheckHandler extends ChannelDuplexHandler {
    /**
     * 日志
     */
    private static final Logger logger = LoggerFactory.getLogger(StatusPringHandler.class);

    /**
     * 空闲会话检测
     * @param ctx 管道
     * @param evt 事件对象
     */
    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent e = (IdleStateEvent) evt;
            if (e.state() == IdleState.READER_IDLE) {
                // TODO: 读空闲，准备断开客户端,测试阶段先不实现
                logger.debug("读空闲，准备断开客户端");
            } else if (e.state() == IdleState.WRITER_IDLE) {
                logger.debug("写空闲，下行一条心跳保持连接");
                // TODO: 下行数据先写死
                ctx.channel().writeAndFlush(Unpooled.copiedBuffer("{\"msgType\": 20, \"txNo\": \"1234567890123\"}\n", CharsetUtil.UTF_8));
            }
        }
    }
}
~~~

使用也比较简单，在initChannel方法里增加两个新的ChannelHandler:

~~~ java
	@Override
	public void initChannel(SocketChannel ch) {
		ch.pipeline()
				// 增加空闲检查器，规定读写各30秒没操作时触发
				.addLast(new IdleStateHandler(30,30,0))
				//自定义实现的空闲处理
				.addLast(idleCheckHandler);
	}
~~~

运行下，现在可以看到在控制台会定时打印程序运行状态的表格。同时在我们的连接终端也会定时收到心跳包。


本节 [源码](https://github.com/guohai163/iot-server/tree/v0.2)


## 下一章节我们将会实现


1. 心跳协议包的处理
2. main disruptor的工作