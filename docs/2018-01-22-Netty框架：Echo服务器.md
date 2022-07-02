---
layout: single
toc: true
---

## Netty客户端/服务器概览

图2-1从**高层次**上展示了一个将要编写的Echo客户端和服务器应用程序。虽然你的主要关注点可能是编写基于Web的用于被浏览器访问的应用程序，但是通过同时实现客户端和服务器，你一定能更加全面地理解Netty的API。

![2ba43fa2529d62a6829b351f.png](assets/img/2ba43fa2529d62a6829b351f.png)

图2-1　Echo客户端和服务器

虽然我们已经谈及到了客户端，但是该图展示的是多个客户端**同时**连接到一台服务器。所能够支持的客户端数量，在理论上，仅受限于系统的**可用资源**（以及所使用的JDK版本**可能**会施加的限制）。

Echo客户端和服务器之间的交互是非常简单的；在客户端建立一个连接之后，它会向服务器发送一个或多个消息，反过来，服务器又会将每个消息回送给客户端。虽然它本身看起来好像用处不大，但它充分地体现了客户端/服务器系统中典型的请求-响应交互模式。

我们将从考察服务器端代码开始这个项目。

## 编写Echo服务器

所有的Netty服务器都需要以下两部分。

1. 至少一个ChannelHandler——该组件实现了服务器对从客户端接收的数据的处理，即它的业务逻辑。
2. 引导——这是配置服务器的启动代码。至少，它会将服务器绑定到它要监听连接请求的端口上。

在本小节的剩下部分，我们将描述Echo服务器的业务逻辑以及引导代码。

### ChannelHandler和业务逻辑（ChannelHandlers and business logic）

我们已经讨论了**Future**和**回调**，并且阐述了它们在**事件驱动设计**中的应用。我们还讨论了**`ChannelHandler`**，它是一个接口族的**父接口**，它的实现负责**接收并响应**事件通知。在Netty应用程序中，所有的数据处理逻辑都包含在这些核心抽象的实现中。

因为你的Echo服务器会响应传入的消息，所以它需要实现**`ChannelInboundHandler`**接口，用来定义**响应入站事件的方法**。这个简单的应用程序只需要用到少量的这些方法，所以继承**`ChannelInboundHandlerAdapter`**类也就足够了，它提供了**`ChannelInboundHandler`**的默认实现。

我们感兴趣的方法是：

- **`channelRead()`**——对于每个传入的消息都要调用；
- **`channelReadComplete()`**——通知ChannelInboundHandler最后一次对channel-Read()的调用是当前批量读取中的最后一条消息；
- **`exceptionCaught()`**——在读取操作期间，有异常抛出时会调用。

该Echo服务器的ChannelHandler实现是EchoServerHandler，如代码清单2-1所示。

```java
// 代码清单2-1　EchoServerHandler
@Sharable  // 标示一个Channel- Handler可以被多个Channel安全地共享
public class EchoServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ByteBuf in = (ByteBuf) msg;
        System.out.println(
            "Server received: " + in.toString(CharsetUtil.UTF_8));     // 将消息记录到控制台
        ctx.write(in);  // 将接收到的消息写给发送者，而不冲刷出站消息
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) {
        ctx.writeAndFlush(Unpooled.EMPTY_BUFFER)
            .addListener(ChannelFutureListener.CLOSE);   // 将未决消息[4]冲刷到远程节点，并且关闭该Channel
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx,
        Throwable cause) {
        cause.printStackTrace();     // 打印异常栈跟踪
        ctx.close();   // 关闭该Channel
    }
}
```

> **未决消息（pending message）**指目前暂存于**`ChannelOutboundBuffer`**中的消息，在下一次调用**`flush()`**或者**`writeAndFlush()`**方法时将会尝试写出到套接字。

**`ChannelInboundHandlerAdapter`**有一个直观的API，并且它的每个方法都可以被重写以挂钩到**`事件生命周期`**的恰当点上。因为需要处理所有接收到的数据，所以你重写了**`channelRead()`**方法。在这个服务器应用程序中，你将数据简单地回送给了远程节点。

重写**`exceptionCaught()`**方法允许你对**`Throwable`**的任何子类型做出反应，在这里你记录了异常并关闭了连接。虽然一个更加完善的应用程序也许会尝试从异常中恢复，但在这个场景下，只是通过简单地关闭连接来通知远程节点发生了错误。

> **如果不捕获异常，会发生什么呢？**

> 每个Channel都拥有一个与之相关联的**`ChannelPipeline`**，其持有一个ChannelHandler的实例链。在默认的情况下，ChannelHandler会把对它的方法的调用转发给链中的下一个ChannelHandler。因此，如果exceptionCaught()方法没有被该链中的某处实现，那么所接收的异常将会被传递到ChannelPipeline的**尾端**并被记录。为此，你的应用程序应该提供**至少有一个**实现了exceptionCaught()方法的ChannelHandler。

除了ChannelInboundHandlerAdapter之外，还有很多需要学习的ChannelHandler的子类型和实现。目前，请记住下面这些关键点：

- 针对不同类型的事件来调用ChannelHandler；
- 应用程序通过实现或者扩展ChannelHandler来挂钩到事件的生命周期，并且提供自定义的应用程序逻辑；
- 在架构上，ChannelHandler有助于保持业务逻辑与网络处理代码的**分离**。这简化了开发过程，因为代码必须不断地演化以响应**不断变化的需求**。

### 引导服务器（Bootstrapping the server）

在讨论过由EchoServerHandler实现的核心业务逻辑之后，我们现在可以探讨引导服务器本身的过程了，具体涉及以下内容：

- 绑定到服务器将在其上监听并接受传入连接请求的端口；
- 配置Channel，以将有关的入站消息通知给EchoServerHandler实例。

> **传输层（Transports）**

> 在网络协议的标准多层视图中，传输层提供了端到端的或者主机到主机的通信服务。因特网通信是建立在TCP传输之上的。除了一些由Java NIO实现提供的服务器端性能增强之外，NIO传输大多数时候指的就是TCP传输。

代码清单2-2展示了EchoServer类的完整代码。

```java
// 代码清单2-2　EchoServer类
public class EchoServer {
    private final int port;

    public EchoServer(int port) {
        this.port = port;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println(
                "Usage: " + EchoServer.class.getSimpleName() +
                " ");
        }
        int port = Integer.parseInt(args[0]);   // 设置端口值（如果端口参数的格式不正确，则抛出一个NumberFormatException）
        new EchoServer(port).start();   // 调用服务器的start()方法
    }
    public void start() throws Exception {
        final EchoServerHandler serverHandler = new EchoServerHandler();
        EventLoopGroup group = new NioEventLoopGroup();   // ❶ 创建Event-LoopGroup
        try {
             ServerBootstrap b = new ServerBootstrap();   //  ❷ 创建Server-Bootstrap
             b.group(group)
                 .channel(NioServerSocketChannel.class)   // ❸ 指定所使用的NIO传输Channel
                 .localAddress(new InetSocketAddress(port))   // ❹ 使用指定的端口设置套接字地址
                .childHandler(new ChannelInitializer(){   // ❺添加一个EchoServer-
Handler到子Channel的ChannelPipeline
                 @Override
                public void initChannel(SocketChannel ch)
                    throws Exception {
                         ch.pipeline().addLast(serverHandler);[5]   // EchoServerHandler被标注为@Shareable，所以我们可以总是使用同样的实例
                    }
                 });
            ChannelFuture f = b.bind().sync();   // ❻ 异步地绑定服务器；调用sync()方法阻塞等待直到绑定完成
            f.channel().closeFuture().sync();   // ❼ 获取Channel的CloseFuture，并且阻塞当前线程直到它完成
        } finally {
            group.shutdownGracefully().sync();   //  ❽ 关闭EventLoopGroup，释放所有的资源
        }
    }
}
```

在➋处，你创建了一个**`ServerBootstrap`**实例。因为你正在使用的是**`NIO`**传输，所以你指定了**`NioEventLoopGroup`**➊来接受和处理新的连接，并且将Channel的类型指定为**`NioServerSocketChannel`**➌。在此之后，你将本地地址设置为一个具有选定端口的**`InetSocketAddress`**➍。服务器将绑定到这个地址以监听新的连接请求。

在➎处，你使用了一个特殊的类——**`ChannelInitializer`**。这是关键。当一个**新的连接**被接受时，一个新的**子Channel**将会被创建，而ChannelInitializer将会把一个你的**`EchoServerHandler`**的实例添加到该Channel的**`ChannelPipeline`**中。正如我们之前所解释的，这个ChannelHandler将会收到有关**入站消息**的通知。

虽然NIO是**可伸缩**的，但是其适当的尤其是关于**多线程处理的配置**并不简单。Netty的设计封装了大部分的复杂性。

接下来你绑定了服务器➏，并**等待**绑定完成。（对**`sync()`**方法的调用将导致当前Thread**`阻塞`**，一直到绑定操作完成为止）。在➐处，该应用程序将会阻塞等待直到服务器的Channel关闭（因为你在Channel的**`Close Future`**上调用了sync()方法）。然后，你将可以关闭**`EventLoopGroup`**，并释放所有的资源，包括所有被创建的线程➑。

这个示例使用了NIO，因为得益于**它的可扩展性和彻底的异步性**，它是目前使用最广泛的传输。但是也可以使用一个不同的传输实现。如果你想要在自己的服务器中使用OIO传输，将需要指定**`OioServerSocketChannel`**和**`OioEventLoopGroup`**。

与此同时，让我们回顾一下你刚完成的服务器实现中的重要步骤。下面这些是服务器的主要代码组件：

- **`EchoServerHandler`**实现了业务逻辑
- **`main()`**方法**`引导`**了服务器

引导过程中所需要的步骤如下：

- 创建一个**`ServerBootstrap`**的实例以引导和绑定服务器
- 创建并分配一个**`NioEventLoopGroup`**实例以进行事件的处理，如接受新连接以及**`读/写`**数据
- 指定服务器绑定的本地的**`InetSocketAddress`**
- 使用一个**`EchoServerHandler`**的实例初始化每一个新的**`Channel`**
- 调用**`ServerBootstrap.bind()`**方法以绑定服务器

在这个时候，服务器已经初始化，并且已经就绪能被使用了。
