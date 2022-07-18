---
layout: post
title:  "物联网的服务端设计(四)重构项目"
date:   2022-07-01 10:10:00
categories: [netty]
tags: [iot, java, netty]
image: /doc-pic/2022/iot.png
---

## 重构项目

在做协议包之前我们先把Handler做个拆，在之前的设计中解码、处理连接、协议解析、断开连接都在同一handler中。但按netty的设计思想是要分为多个，多个handler通过pipeline进行串联。
接下来我们创建4个handler分别是：
1. InitChannelHandler 处理终端的首次连接并创建对应的会话
2. IotProtocolHandler 协议处理类，和之前的解码器拆开后，不用再处理连包问题，协议处理类就可以是标记为可共享的 @Sharable 
3. QuitHandler 协议处理类，主要是处理终端正常退出时删除相应的会话标识。以及在客户端发送异常包时及时踢掉相应的终端。
4. EncoderHandler 编码器，负责在下行会话时把对象json后再转为bytebuf对象。

~~~ java
ch.pipeline()
		// 链路 head <=> initChannelHandler <=> jsonDecoder <=> iotProtocolHandler <=> encoder <=> idleCheck <=> tail
		// 入站 从head到tail ，出站 从tail到head

		// netty要求ChannelHandler是每个线程一份的，就算指定bean的scope是原型也无效。
		// 这里有三种解决方案
		// 1. 每次都是new的，但把需要依赖spring完成初始化的传参进去
		// 2. 使用一个ApplicationContextHolder工具类，在handler中通过applicationContext.getBean来获取
		// 3. 如果能保证线程安全的情况下 给ChannelHandler增加@Sharable注解


		// 先增加一个初始化连接的
		.addLast("initChannel",initChannelHandler)
        // 再增加一个解码的，因要处理半包问题。是线程不安全的需要对每个channel进行new
		.addLast("jsonDecoder", new JsonObjectDecoder())
        // 协议处理
		.addLast("iotProtocol", iotProtocolHandler)
		// 出站编码器
		.addLast("encoder", new EncoderHandler())
        // 处理客户端退出时的事件
		.addLast("quit", quitHandler)

		// 增加空闲检查器，规定读写各30秒没操作时触发
		.addLast("IdleState", new IdleStateHandler(30,30,0))
		//自定义实现的空闲处理
		.addLast("idleCheck", idleCheckHandler);
~~~


## 协议处理类

在我们的项目重构后，JsonObjectDecoder已经帮我们把bytebuf按json串分好组。给到iotProtocolHandler类的不需要再分割直接转换就行，我们新的类需要集成下MessageToMessageDecoder。来实现decode方法。

为了减少netty中的ChannelHandler的占用时间，腾出更多的时间来处理其他客户端。我们的decode中只负责取出byte中的值转为String后就交由后续的disruptor来处理。这也是能让一个微服务处理更多连接的基础。

~~~ java
@Slf4j
@Component
@ChannelHandler.Sharable
public class IotProtocolHandler extends MessageToMessageDecoder<ByteBuf> {
    /**
     * 主事件循环
     */
    private final MainEventProducer mainEventProducer;

    public IotProtocolHandler(MainEventProducer mainEventProducer) {
        this.mainEventProducer = mainEventProducer;
    }

    @Override
    protected void decode(ChannelHandlerContext ctx, ByteBuf msg, List<Object> out) throws Exception {

        try{
            // 把接收到的流转写成string字符串
            String message = msg.toString(CharsetUtil.UTF_8);
            log.info(message);

            // 向队列发布服务,
            mainEventProducer.onData(ctx.channel(), message);

        }catch (Exception e){
            e.printStackTrace();
        }
    } 
}
~~~

## Disruptor的引入

Disruptor是英国外汇交易公司LMAX开发的一个高性能队列，研发的初衷是解决内存队列的延迟问题（在性能测试中发现竟然与I/O操作处于同样的数量级）。基于Disruptor开发的系统单线程能支撑每秒600万订单


Disruptor 是基于一个环形队列来实现的，我们需要先进行队列的初始化。建议初始化的队列大小为预计为来单一服务器的连接数*5。同时Disruptor是个队列就也会区分为生产者 [MainEventProducer] 和消费者 [MainEventHandler]，在生产者这里我们要对消息进行下解析以区分不用的消息类型。
理想情况下我们需要让控制类消息和日志类消息走不同的队列，以减少控制类消息的延迟情况。

~~~ java
/**
 * 主事件队列生产者
 * @author guohai
 */
@Component
public class MainEventProducer {

    private final Disruptor<EventInfo> disruptor;
    /**
     * 存储数据一个环形队列
     */
    private final RingBuffer<EventInfo> ringBuffer;

    /**
     * 主事件消费者
     */
    MainEventHandler mainEventHandler;

    /**
     * 初始化的队列大小，生产环境中尽量设置的大一些
     */
    private final int INIT_LOGIC_EVENT_CAPACITY = 1024 ;

    public MainEventProducer(MainEventHandler mainEventHandler){
        this.mainEventHandler = mainEventHandler;
        // 初始化
        disruptor = new Disruptor<>(EventInfo::new, INIT_LOGIC_EVENT_CAPACITY,
                DaemonThreadFactory.INSTANCE);
        // 指定消费者
        disruptor.handleEventsWith(mainEventHandler);
        ringBuffer = disruptor.getRingBuffer();
        //启动队列
        disruptor.start();
    }

    /**
     * 发布一条消息入队
     * @param channel
     * @param message
     */
    public void onData(Channel channel, String message){
        // TODO: 未来这里需要区分消息类型，以区分控制类和日志类消息
        ProtocolBase protocolBase = new Gson().fromJson(message, ProtocolBase.class);

        // 获取队列里的位置 ，准备入队、
        long sequence = ringBuffer.next();

        try{
            EventInfo newEventInfo = ringBuffer.get(sequence);
            newEventInfo.setEventType(protocolBase.getMsgType());
            newEventInfo.setChannel(channel);
            newEventInfo.setMessage(message);
        }finally {
            ringBuffer.publish(sequence);
        }
    }

    /**
     * 停止服务
     */
    public void stop(){
        disruptor.shutdown();
    }
}
~~~

再来看消费者的代码,消费者这里我们会把不同类型的消息交由不同的实现类进行二次处理。

对于登录类消息，除了用来在本地标示会话和设备关系外。我们还需要 __通知后部业务程序__ 该设备在哪个微服务上登录的，这样下行消息时后端的服务也知道要把消息抛给哪个前置程序。

~~~ java
/**
 * 主事件的消费者
 * @author guohai
 */
@Component
public class MainEventHandler implements EventHandler<EventInfo> {

    /**
     * 事件MAP
     */
    private final Map<EventType, IotEventHandler> eventMap = new HashMap<>(2);


    public MainEventHandler(LoginEventHandler loginEventHandler, HeartbeatEventHandler heartbeatEventHandler){
        eventMap.put(EventType.CLIENT_REGISTER, loginEventHandler);
        eventMap.put(EventType.HEART_BEAT, heartbeatEventHandler);
    }


    /**
     * 当有事件时
     * @param eventInfo
     * @param l
     * @param b
     * @throws Exception
     */
    @Override
    public void onEvent(EventInfo eventInfo, long l, boolean b) throws Exception {

        IotEventHandler eventHandler = eventMap.get(eventInfo.getEventType());

        eventHandler.onEvent(eventInfo.getChannel(), eventInfo.getMessage());
    }
}

~~~

本节 [源码](https://github.com/guohai163/iot-server/tree/v0.3)