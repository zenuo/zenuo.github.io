---
title: "可扩展的事件多路复用：epoll与kqueue"
date: 2019-05-01T19:23:13+08:00
categories: ["tech"]
---

> 翻译自[Scalable Event Multiplexing: epoll vs. kqueue](https://people.eecs.berkeley.edu/~sangjin/2012/12/21/epoll-vs-kqueue.html)

我比`BSD`更喜欢`Linux`，但我确实想在Linux中使用BSD的**`kqueue`**功能。

## 什么是事件多路复用（event multiplexing）

假设您有一个简单的Web服务器，并且当前有两个打开的**连接（套接字）**。当服务器从任一连接收到HTTP请求时，它应该向客户端发送HTTP响应。但是你不知道两个客户端中的哪一个会先发送消息，何时发送消息。**`BSD Socket API`**的阻塞行为意味着如果在一个连接上调用**`recv()`**，您将无法响应另一个连接上的请求。这是您需要**I/O多路复用（I/O multiplexing）**的地方。

I/O复用的一种简单方法是**为每个连接提供一个进程/线程**，以便在一个连接中阻塞不会影响其他连接。通过这种方式，您可以有效地将所有**毛茸茸**的**调度/多路复用问题**委托给**OS内核**。这种多线程架构带来（可以说）高成本。维护大量线程对于内核来说并非易事。为每个连接设置单独的堆栈会增加内存占用，从而降低CPU**`缓存局部性（cache locality）`**。

如何在没有线程连接的情况下实现I / O复用？您可以使用**非阻塞套接字操作**为每个连接**执行繁忙等待轮询**，但这太浪费了。我们需要知道的是哪个套接字**准备**好了。因此，操作系统内核在您的**应用程序**和**内核**之间提供了一个单独的通道，此通道会在您的某些套接字准备就绪时**通知**。这就是**`select()/poll()`**的工作原理，基于**`就绪模型（readiness model）`**。

## 回顾：select()

select()和poll()在它们的工作方式上非常相似。让我快速回顾一下select()的样子。

```c
select(int nfds, fd_set *r, fd_set *w, fd_set *e, struct timeval *timeout)
```

使用**`select()`**，您的应用程序需要提供**三个兴趣集（interest sets）r，w和e**。每个集都表示为文件描述符的**位图**。例如，如果您对从**文件描述符6**中**读取**感兴趣，则将**`r`**的**第六位**设置为**`1`**。这个调用是阻塞的，直到感兴趣集中的**一个或多个文件描述符**准备就绪，这样您就可以对这些文件描述符执行**没有阻塞的操作**。返回后，内核将**覆盖位图**以指定哪些文件描述符已**准备就绪**。

在可扩展性方面，我们可以找到四个问题：

1. 这些位图的大小是**固定**的（**`FD_SETSIZE`**，通常为**`1024`**）。但是，有一些方法可以解决这个限制。
2. 由于位图被内核覆盖，用户应用程序应该为每个调用重新填充兴趣集。
3. 用户应用程序和内核应扫描每个调用的整个位图，以确定哪些**文件描述符**属于**兴趣集**和**结果集**。这对于结果集来说尤其**低效**，因为它们可能非常**稀疏**（即，在给定时间只有少数文件描述符准备好）。
4. 内核应迭代整个**兴趣集**，以找出哪些文件描述符**已准备好**，再次针对每个调用。如果它们都没有准备就绪，则内核再次迭代以为每个套接字注册内部事件处理程序。

## 回顾：poll()

poll()旨在解决其中的一些问题。

```c
poll(struct pollfd *fds, int nfds, int timeout)

struct pollfd {
    int fd;
    short events;
    short revents;
}
```

**`poll()`**不依赖于位图，而是依赖于文件描述符数组（因此解决了问题＃1）。通过为感兴趣（事件）和结果（revents）提供单独的字段，如果用户应用程序正确维护并重新使用该数组，则问题＃2也会得到解决。如果轮询分离数组而不是字段，问题＃3可能已经修复。最后一个问题是固有的，不可避免的，因为select()和poll()都是无状态的；内核不会在内部维护兴趣集。

## 为什么可扩展性很重要

如果您的网络服务器需要维持相对较少的连接数（例如，几百个）并且连接速率很慢（再次，每秒100个连接），则select()或poll()就足够了。也许你甚至不需要打扰事件驱动的编程;坚持使用**多进程/线程**架构。如果性能不是您的首要考虑因素，那么编程的简易性和灵活性就是最重要的。 `Apache Web`服务器就是一个很好的例子。

但是，如果您的服务器应用程序是网络密集型的（例如，1000个并发连接和/或高连接速率），您应该对性能非常认真。这种情况通常被称为[**c10k问题**](http://www.kegel.com/c10k.html)。使用select()或poll()，您的网络服务器几乎不会执行任何有用的操作，但会在如此高的负载下浪费宝贵的CPU周期。

假设有10000个并发连接。通常，只有**少数**文件描述符（例如10个）可以读取。对于每个select()/poll()调用，无理由地复制和扫描剩余的9990个文件描述符。

如前所述，这个问题来自于那些select()/poll()接口是**无状态**的。 Banga等人在`USENIX ATC 1999`上发表的[论文](http://static.usenix.org/event/usenix99/full_papers/banga/banga.pdf)提出了一个新观点：有状态的兴趣集。内核不是为每个系统调用提供整个兴趣集，而是在**内部**维护兴趣集。在**`decalre_interest()`**调用时，内核会逐步更新兴趣集。用户应用程序通过**`get_next_event()`**从内核调度新事件。

受研究结果的启发，Linux和FreeBSD分别提出了他们自己的实现，epoll和kqueue。这意味着缺乏可移植性，因为基于epoll的应用程序无法在FreeBSD上运行。令人遗憾的是，kqueue在技术上优于epoll，因此没有充分理由证明epoll的存在。

## Linux中的epoll

epoll接口包含三个系统调用：

```c
int epoll_create(int size);
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
```

**`epoll_ctl()`**和**`epoll_wait()`**基本上分别对应于上面的**`decalre_interest()`**和**`get_next_event()`**。**`epoll_create()`**创建一个上下文作为文件描述符，而上面提到的文件隐含地假设每个进程上下文。在内部，Linux内核中的epoll实现与select()/poll()实现没有太大区别。唯一的区别是它是否有状态。这是因为它们的设计目标完全相同（套接字/管道的事件多路复用）。有关更多信息，请参阅Linux源代码树中的**`fs/select.c`**（用于select和poll）和**`fs/eventpoll.c`**（用于epoll）。

你也可以在epoll的[早期版本](http://lkml.indiana.edu/hypermail/linux/kernel/0010.3/0003.html)中找到Linus Torvalds的一些初步想法。

## FreeBSD中的kqueue

与epoll一样，kqueue也支持每个进程的多个上下文（兴趣集）。 **`kqueue()`**执行与**`epoll_create()`**相同的操作。但是，**`kevent()`**调用使用**`kevent()`**集成了**`epoll_ctl()`**（调整兴趣集）和**`epoll_wait()`**（检索事件）的角色。

```c
int kqueue(void);
int kevent(int kq, const struct kevent *changelist, int nchanges, 
           struct kevent *eventlist, int nevents, const struct timespec *timeout);
```

从编程的简易性来看，实际上kqueue比epoll复杂一点。这是因为kqueue以**更抽象**的方式设计，以实现**通用性**。让我们看一下**`struct kevent`**的外观。

```c
struct kevent {
     uintptr_t       ident;          /* identifier for this event */
     int16_t         filter;         /* filter for event */
     uint16_t        flags;          /* general flags */
     uint32_t        fflags;         /* filter-specific flags */
     intptr_t        data;           /* filter-specific data */
     void            *udata;         /* opaque user data identifier */
 };
```

虽然这些字段的详细信息超出了本文的范围，但您可能已经注意到没有明确的文件描述符字段。这是因为kqueue**不仅仅**被设计为用于套接字事件多路复用的select()/poll()的替代，而是作为各种类型的操作系统事件的**一般机制**。

**`filter`**字段指定内核事件的**类型**。如果它是**`EVFILT_READ`**或**`EVFILT_WRITE`**，则kqueue的工作方式类似于epoll。在这种情况下，**`ident`**字段表示文件描述符。**`ident`**字段可以表示其他类型的标识符，例如**`进程ID`**和**信号编号**，这取决于**过滤器类型**。详细信息可以在[手册页](http://www.freebsd.org/cgi/man.cgi?query=kqueue&sektion=2)或[论文](http://people.freebsd.org/~jlemon/papers/kqueue.pdf)中找到。

## epoll和kqueue的比较

### 性能

在性能方面，epoll设计有一个缺点；它不支持**单个系统调用中的兴趣集的多个更新**。当您有100个文件描述符来更新其在兴趣集中的状态时，您必须进行100次**`epoll_ctl()`**调用。如文章所述，过度系统调用导致的性能下降非常显着。我猜这是Banga等人原创作品的遗产，因为**`declare_interest()`**也只支持每次调用的一次更新。相反，您可以在单个**`kevent()`**调用中指定多个兴趣更新。

### 非文件支持

在我看来，另一个更重要的问题是epoll的范围有限。因为它旨在提高**select()/poll()**的性能，但仅此而已，epoll仅适用于文件描述符。这有什么问题？

经常引用“在Unix中，一切都是文件”。这大多是真的，但并非总是如此。例如，计时器不是文件。信号不是文件。信号量不是文件。进程不是文件。（在Linux中，）网络设备不是文件。类UNIX操作系统中有许多不是文件的东西。您不能使用**`select()/ poll()/epoll()`**来复制那些“事物”。除套接字外，典型的网络服务器还管理**各种类型**的资源。您可能希望使用单一，统一的界面监控它们，但您不能。要解决此问题，Linux支持许多补充系统调用，例如**`signalfd()`**，**`eventfd()`**和**`timerfd_create()`**，它们将非文件资源转换为文件描述符，以便您可以将它们与**`epoll()`**复用。但这看起来并不优雅......你真的想要为每种类型的资源进行专门的系统调用吗？

在**`kqueue`**中，通用的*`struct kevent`*结构支持各种**非文件事件**。例如，您的应用程序可以在子进程退出时收到通知（使用**`filter = EVFILT_PROC`**，**`ident = pid`**和**`fflags = NOTE_EXIT`**）。即使当前内核版本不支持某些资源或事件类型，也会在未来的内核版本中对其进行扩展，而不会对API进行任何更改。

## 磁盘文件支持

最后一个问题是epoll甚至不支持所有类型的文件描述符; **`select()/poll()/epoll()`**不适用于**常规（磁盘）文件**。这是因为epoll对准备模型有**很强的假设**；监视套接字的准备情况，以便套接字上的后续IO调用不会阻塞。但是，磁盘文件不适合此模型，因为它们总是准备就绪。

当数据**未缓存**在内存中时磁盘I/O**阻塞**，而不是因为客户端没有发送消息。对于磁盘文件，**完成通知模型（completion notification model）**适合。在此模型中，您只需对磁盘文件发出I/O操作，并在完成后收到通知。kqueue支持使用**`EVFILT_AIO`**过滤器类型的此方法，以及**`POSIX AIO`**函数，例如**`aio_read()`**。在Linux中，您应该简单地祈祷磁盘访问不会以**高缓存命中率**阻塞（在许多网络服务器中非常常见），或者具有单独的线程以便**磁盘I/O阻塞**不会影响**网络套接字**处理（例如，[FLASH](http://www.cs.princeton.edu/~vivek/pubs/flash_usenix_99/flash.pdf)体系结构） ）。

在我们之前的[MegaPipe论文](http://www.eecs.berkeley.edu/~sangjin/static/pub/osdi2012_megapipe.pdf)中，我们提出了一个新的编程接口，它完全基于完成通知模型，适用于磁盘和非磁盘文件。