---
layout: post
title:  "物联网的服务端设计(二)"
date:   2022-06-28 10:10:00
categories: [develop]
tags: [iot, java, netty]
image: /doc-pic/2022/iot.svg
---

引用Spring官方的一句话，让你简单的创建一个项目。
>Spring Boot makes it easy to create stand-alone, production-grade Spring based Applications that you can "just run".
这么好用的框架我们也要用起来，不要只做为web项目使用。让Spring帮我们管理对象多方便啊。

## 新建项目
正常创建一个SpringBoot2.6.x的项目。在POM里引一下Netty。

~~~ xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.6.9</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>org.guohai</groupId>
	<artifactId>iot-server</artifactId>
	<version>0.0.1</version>
	<name>iot-server</name>
	<description>iot server by netty</description>
	<properties>
		<java.version>11</java.version>
	</properties>
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter</artifactId>
		</dependency>
		<dependency>
			<groupId>io.netty</groupId>
			<artifactId>netty-all</artifactId>
		</dependency>
	</dependencies>
	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
				<configuration>
					<excludes>
						<exclude>
							<groupId>org.projectlombok</groupId>
							<artifactId>lombok</artifactId>
						</exclude>
					</excludes>
				</configuration>
			</plugin>
		</plugins>
	</build>
</project>

~~~

同时会自动 创建一个main类文件。做为我们的主引导文件。

首先要创建的是两个事件循环组，分别用户来维护客户端的连接和数据的读写。其中一个构建参数的方法是事件组里的线程数量，如果不进行显示声明会自动创建CPU核心数x2的线程。如果工作在类似docker的容器里该参数会不准确，我们需要显示声明下。其中boosGroup只负责连接我们把线程数设置为1，workerGroup为处理数据的读写线程数可以稍微多一些。这里我们设置为2

~~~ java
	/**
	 * 主事件，负责连接。单一线程就行
	 */
	private final EventLoopGroup bossGroup = new NioEventLoopGroup(1);
	/**
	 * 负责处理业务,不设置线程数时为CPU核心*2.如果运行在容器状态下会不准，建议手动设置
	 */
	private final EventLoopGroup workerGroup = new NioEventLoopGroup(2);
~~~

接下来准备启动我们的Netty的服务进程，我们的启动肯定希望是在整个spring资源加载完毕后。这里可以实现一下CommandLineRunner接口的run方法。

~~~ java
	/**
	 * 实现自定义的run方法
	 * @param args 输入的参数
	 * @throws Exception 抛出异常
	 */
	@Override
	public void run(String... args) throws Exception {
		try{
			ServerBootstrap bootstrap = new ServerBootstrap();
			bootstrap
					.group(bossGroup, workerGroup)
					// 这里还可以支持其他的实现，
					// 比如在Linux下可以用基于EpollServerSocketChannel
					// 在mac下可以使用KQueueServerSocketChannel
					// 在这里我们用比较通用的NioServerSocketChannel实现
					.channel(NioServerSocketChannel.class)
					.childHandler(new ChannelInitializer<SocketChannel>() {
						@Override
						public void initChannel(SocketChannel ch) {

						}
					});
			// 绑定端口
			ChannelFuture channelFuture = bootstrap.bind(SERVER_PORT).sync();
			logger.info("Server start listen port :" + SERVER_PORT);
			channelFuture.channel().closeFuture().sync();
		}finally {
			workerGroup.shutdownGracefully();
			bossGroup.shutdownGracefully();
		}

	}
~~~

运行我们的程序，目前已经可以开始监听本机的 SERVER_PORT 端口，但客户端连接上来，还不会有任何的回应。我们还需要实现一个最简单的 ChannelHandler。

为了下一步json的解码准备我们起名叫 DecoderHandler 。需要继承自 JsonObjectDecoder 类，并覆写下 extractObject方法。

JsonObjectDecoder类的主要作用是可以帮我们处理json流的分包和半包问题。保证每次送到extractObject方法里都是一个完整的json串

~~~ java
    /**
     * 识别到一个正确的json数据，进行处理
     * @param ctx channel
     * @param buffer bytebuff
     * @param index 此次包的开始点
     * @param length 此次包的长度
     * @return 返回一个bytebuf做后续处理，如果不需要可以返回Unpooled.EMPTY_BUFFER
     */
    @Override
    protected ByteBuf extractObject(ChannelHandlerContext ctx, ByteBuf buffer,
                                    int index, int length){
        try{
            // 首先按指定的位置标记从 buffer中读取数据到新的bytebuf中。
            // 这里的ByteBuf是netty重写的nio中的ByteBuffer性能更好
            ByteBuf byteBuf = buffer.slice(index, length);

            // 把接收到的流转写成string字符串
            try (ByteBufInputStream inputStream = new ByteBufInputStream(byteBuf)) {

                String message = byteBuf.readSlice(length).toString(0, length, CharsetUtil.UTF_8);
                logger.info(message);
                // 测试阶段直接回写数据
                ctx.writeAndFlush(Unpooled.copiedBuffer(message, CharsetUtil.UTF_8));
            }

        }catch (Exception e){
            e.printStackTrace();
        }
        return Unpooled.EMPTY_BUFFER;
    }

~~~

然后回到上一步的initChannel中增加一个 pipeline的channelHandler.

~~~ java
	@Override
	public void initChannel(SocketChannel ch) {
		ch.pipeline()
			.addLast(new DecoderHandler());
	}
~~~

再次运行我们的程序，并使用nc进行一下测试。可以看到服务端已经可以回写我们发送的字符串。

~~~ shell
$ nc 127.0.0.1 4100
{"msgType": 20, "txNo": "1234567890123"} 
{"msgType": 20, "txNo": "1234567890123"}

~~~

本节 [源码](https://github.com/guohai163/iot-server/tree/v0.1)

### 下一章节我们将会实现
1. 一个客户端的空闲检测，并踢掉空闲的客户端
2. 服务端空闲，并下发心跳包
3. 定时的netty连接状态打印