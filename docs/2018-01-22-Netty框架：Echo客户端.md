---
layout: single
toc: true
---

Echo客户端将会：

1. 连接到服务器
2. 发送一个或者多个消息
3. 对于每个消息，等待并接收从服务器发回的相同的消息
4. 关闭连接

编写客户端所涉及的两个主要代码部分也是业务逻辑和引导，和你在服务器中看到的一样。

## 通过ChannelHandler实现客户端逻辑（Implementing the client logic with ChannelHandlers）

如同服务器，客户端将拥有一个用来处理数据的ChannelInboundHandler。在这个场景下，你将扩展SimpleChannelInboundHandler类以处理所有必须的任务，如代码清单2-3所示。这要求重写下面的方法：

- **`channelActive()`**——在到服务器的连接已经建立之后将被调用；
- **`channelRead0()`**——当从服务器接收到一条消息时被调用；
- **`exceptionCaught()`**——在处理过程中引发异常时被调用。

```java
// 代码清单2-3　客户端的ChannelHandler
@Sharable   // 标记该类的实例可以被多个Channel共享
public class EchoClientHandler extends
    SimpleChannelInboundHandler<ByteBuf> {
    @Override
    public void channelActive(ChannelHandlerContext ctx) {
        ctx.writeAndFlush(Unpooled.copiedBuffer("Netty rocks!",   // 当被通知Channel是活跃的时候，发送一条消息
        CharsetUtil.UTF_8));
    }

    @Override
    public void channelRead0(ChannelHandlerContext ctx, ByteBuf in) {
        System.out.println(  // 记录已接收消息的转储
            "Client received: " + in.toString(CharsetUtil.UTF_8));
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx,   // 在发生异常时，记录错误并关闭Channel
        Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }
}
```

首先，你重写了**`channelActive()`**方法，其将在**一个连接建立时**被调用。这确保了数据将会被尽可能快地写入服务器，其在这个场景下是一个编码了字符串`Netty rocks!`的字节缓冲区。

接下来，你重写了**`channelRead0()`**方法。每当接收数据时，都会调用这个方法。需要注意的是，由服务器发送的消息可能会被**分块接收（received in chunks）**。也就是说，如果服务器发送了5字节，那么不能保证这5字节会被一次性接收。即使是对于这么少量的数据，channelRead0()方法也**可能**会被调用两次，第一次使用一个持有3字节的ByteBuf（Netty的字节容器），第二次使用一个持有2字节的ByteBuf。作为一个面向流的协议，TCP保证了字节数组将会按照服务器发送它们的**顺序**被接收。

重写的第三个方法是**`exceptionCaught()`**。如同在**`EchoServerHandler`**（见代码清单2-2）中所示，记录Throwable，关闭Channel，在这个场景下，终止到服务器的连接。

> **`SimpleChannelInboundHandler`**与**`ChannelInboundHandler`**

> 你可能会想：为什么我们在客户端使用的是SimpleChannelInboundHandler，而不是在EchoServerHandler中所使用的ChannelInboundHandlerAdapter呢？这和两个因素的相互作用有关：业务逻辑如何处理消息以及Netty如何管理资源。在客户端，当channelRead0()方法完成时，你已经有了传入消息，并且已经处理完它了。当该方法返回时，SimpleChannelInboundHandler负责**释放**指向保存该消息的ByteBuf的内存引用。在EchoServerHandler中，你仍然需要将传入消息回送给发送者，而write()操作是异步的，直到channelRead()方法返回后**可能**仍然没有完成（如代码清单2-1所示）。为此，EchoServerHandler扩展了ChannelInboundHandlerAdapter，其在这个时间点上不会释放消息。消息在EchoServerHandler的**channelReadComplete()**方法中，当**writeAndFlush()**方法被调用时被释放（见代码清单2-1）。

## 引导客户端

如同将在代码清单2-4中所看到的，引导客户端类似于引导服务器，不同的是，客户端是使用主机和端口参数来连接远程地址，也就是这里的Echo服务器的地址，而不是绑定到一个一直被监听的端口。

```java
// 代码清单2-4　客户端的主类
public class EchoClient {
    private final String host;
    private final int port;

    public EchoClient(String host, int port) {
        this.host = host;
        this.port = port;
    }

    public void start() throws Exception {
       EventLoopGroup group = new NioEventLoopGroup();
        try {  // 创建Bootstrap
            Bootstrap b = new Bootstrap();   // 指定EventLoopGroup以处理客户端事件；需要适用于NIO的实现
            b.group(group)
                 .channel(NioSocketChannel.class)   // 适用于NIO传输的Channel类型
                 .remoteAddress(new InetSocketAddress(host, port))   // 设置服务器的InetSocketAddr-ess
                .handler(new ChannelInitializer<SocketChannel>() {  // 在创建Channel时，向ChannelPipeline中添加一个Echo-ClientHandler实例
                 @Override
                public void initChannel(SocketChannel ch)
                    throws Exception {
                   ch.pipeline().addLast(
                        new EchoClientHandler());
                    }
                });
            ChannelFuture f = b.connect().sync();   // 连接到远程节点，阻塞等待直到连接完成
            f.channel().closeFuture().sync();    // 阻塞，直到Channel关闭
        } finally {
            group.shutdownGracefully().sync();     // 关闭线程池并且释放所有的资源
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println(
                "Usage: " + EchoClient.class.getSimpleName() +
                " <host> <port>");
            return;
        }

        String host = args[0];
        int port = Integer.parseInt(args[1]);
        new EchoClient(host, port).start();
    }
}
```

和之前一样，使用了NIO传输。注意，你可以在客户端和服务器上分别使用不同的传输。例如，在服务器端使用NIO传输，而在客户端使用OIO传输。

让我们回顾一下这一节中所介绍的要点：

- 为初始化客户端，创建了一个**`Bootstrap`**实例
- 为进行事件处理分配了一个**NioEventLoopGroup**实例，其中事件处理包括创建新的连接以及处理入站和出站数据
- 为服务器连接创建了一个**InetSocketAddress**实例
- 当连接被建立时，一个**EchoClientHandler**实例会被安装到（该Channel的）**ChannelPipeline**中
- 在一切都设置完成后，调用**Bootstrap.connect()**方法连接到远程节点

完成了客户端，你便可以着手构建并测试该系统了。