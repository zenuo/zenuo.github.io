---
layout: single
toc: true
---

> 本文翻译自[How TCP backlog works in Linux](http://veithen.github.io/2014/01/01/how-tcp-backlog-works-in-linux.html)。

当某个应用程序使用[listen系统调用](http://linux.die.net/man/2/listen)将一个socket置为`LISTEN`状态时，需要为这个socket设置参数`backlog`，该参数通常被描述为传入（incoming）连接队列的数量限制。

![TCP state diagram](/assets/img/3d75825650e82a8afd29e773.png)

因为TCP使用三步握手（3-way handshake），在一个传入的连接在到达`ESTABLISHED`状态之前必须经过中间（intermediate）状态`SYN RECEIVED`，并且可由[accept系统调用](http://linux.die.net/man/2/accept)返回到应用程序（请参阅上面复制的[TCP状态图](http://commons.wikimedia.org/wiki/File:Tcp_state_diagram_fixed.svg)）。这意味着TCP/IP堆栈有两个选项来实现`LISTEN`状态的socket的积压队列（backlog queue）：

1) 使用大小由`listen系统调用`的`backlog`参数决定的单队列实现。当某个connection接收`SYN`分组时，它会发回`SYN/ACK`分组并将连接入列；当接收到相应的`ACK`分组时，连接将其状态改变为`ESTABLISHED`并且有资格切换到应用程序。也就是说，队列中包含两种不同状态——`SYN RECEIVED`和`ESTABLISHED`，只有后一种状态的connection才能通过`accept系统调用`返回给应用程序。

2) 使用一个`SYN`队列（未完成的连接队列）和一个`accept`队列（已完成的连接队列）。状态`SYN RECEIVED`中的connection被添加到`SYN`队列中，并且当它们的状态变为`ESTABLISHED`时，即当接收到3次握手中的`ACK`分组时，移动到accept队列。顾名思义，`accept系统调用`然后只是为了消费（consume）来自accept队列的连接而实现。在这种情况下，`listen系统调用`的`backlog`参数确定accept队列的大小。

从历史上看，BSD派生的TCP实现使用第一种选项，意味着当达到最大backlog时，系统将不再发回`SYN/ACK`分组以响应`SYN`分组。通常，TCP实现只会丢弃`SYN`分组（而不是响应`RST`分组），以便客户端重试。这是W. Richard Stevens的经典教材[TCP/IP详解 卷3](https://book.douban.com/subject/26790662/)的第14.5节`listen Backlog Queue`描述的内容。

请注意，Stevens实际上解释了BSD实现确实使用了两个单独的队列，但它们表现为单个队列，其固定的最大大小由`backlog参数`确定（但不一定完全等于），即BSD在逻辑上表现如第一个选项所述：

> 队列限制适用于[...]不完整连接队列上的条目数和[...]已完成连接队列[...]上的条目数之和。

在Linux上，事情是不同的，如`listen系统调用`的[手册页](http://linux.die.net/man/2/listen)中所述：

> Linux 2.2修改了TCP socket的`backlog`参数的行为。现在它指定了等待被accept的`完全`建立的套接字的队列长度，而不是`未完成`的连接请求的数量。可以在文件`/proc/sys/net/ipv4/tcp_max_syn_backlog`中设置`未完成`的socket队列的长度。

这意味着当前的Linux版本使用具有两个不同队列的第二个选项：具有由系统范围设置指定的大小的`SYN`队列和具有由应用程序指定的大小的accept队列。

现在有趣的问题是，如果接受队列已满并且需要将连接从SYN队列移动到接受队列，即当接收到3次握手的ACK分组时，这种实现如何表现。这种情况由`net/ipv4/tcp_minisocks.c`中的`tcp_check_req`函数处理，相关代码如下：

```c
child = inet_csk(sk)->icsk_af_ops->syn_recv_sock(sk, skb, req, NULL);
if (child == NULL)
        goto listen_overflow;
```

对于IPv4，第一行代码实际调用`net/ipv4/tcp_ipv4.c`中的`tcp_v4_syn_recv_sock`函数，包含以下代码：

```c
if (sk_acceptq_is_full(sk))
        goto exit_overflow;
```
此处的代码对accept队列进行了check。`exit_overflow`标签之后的代码将执行一些清理，更新`/proc/net/netstat`中的`ListenOverflows`和`ListenDrops`统计信息，然后返回`NULL`。这将引发`tcp_check_req`函数中的`listen_overflow`代码的执行：

```c
listen_overflow:
        if (!sysctl_tcp_abort_on_overflow) {
                inet_rsk(req)->acked = 1;
                return NULL;
        }
```

这意味着除非`/proc/sys/net/ipv4/tcp_abort_on_overflow`被置为`1`（在这种情况下，上面显示的代码之后的代码将发送一个`RST`分组），这种实现基本上不做处理。

总而言之，如果Linux中的TCP实现接收到3次握手的`ACK`分组并且accept队列已满，它将基本上忽略该分组。乍看起来很奇怪，但是别忘记有一个与`SYN RECEIVED`状态相关联的定时器：若没有收到`ACK`分组（或者如果它被忽略，如此处所考虑的情况），那么TCP实现将重新发送`SYN / ACK`分组（具有由`/proc/sys/net/ipv4/tcp_synack_retries`指定的重试次数，并使用[指数退避算法](http://en.wikipedia.org/wiki/Exponential_backoff)）。

对于尝试连接（并发送数据）到达已达到其最大backlog的socket的客户端，可以在以下数据包跟踪中看到：

```
0.000  127.0.0.1 -> 127.0.0.1  TCP 74 53302 > 9999 [SYN] Seq=0 Len=0
  0.000  127.0.0.1 -> 127.0.0.1  TCP 74 9999 > 53302 [SYN, ACK] Seq=0 Ack=1 Len=0
  0.000  127.0.0.1 -> 127.0.0.1  TCP 66 53302 > 9999 [ACK] Seq=1 Ack=1 Len=0
  0.000  127.0.0.1 -> 127.0.0.1  TCP 71 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
  0.207  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
  0.623  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
  1.199  127.0.0.1 -> 127.0.0.1  TCP 74 9999 > 53302 [SYN, ACK] Seq=0 Ack=1 Len=0
  1.199  127.0.0.1 -> 127.0.0.1  TCP 66 [TCP Dup ACK 6#1] 53302 > 9999 [ACK] Seq=6 Ack=1 Len=0
  1.455  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
  3.123  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
  3.399  127.0.0.1 -> 127.0.0.1  TCP 74 9999 > 53302 [SYN, ACK] Seq=0 Ack=1 Len=0
  3.399  127.0.0.1 -> 127.0.0.1  TCP 66 [TCP Dup ACK 10#1] 53302 > 9999 [ACK] Seq=6 Ack=1 Len=0
  6.459  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
  7.599  127.0.0.1 -> 127.0.0.1  TCP 74 9999 > 53302 [SYN, ACK] Seq=0 Ack=1 Len=0
  7.599  127.0.0.1 -> 127.0.0.1  TCP 66 [TCP Dup ACK 13#1] 53302 > 9999 [ACK] Seq=6 Ack=1 Len=0
 13.131  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
 15.599  127.0.0.1 -> 127.0.0.1  TCP 74 9999 > 53302 [SYN, ACK] Seq=0 Ack=1 Len=0
 15.599  127.0.0.1 -> 127.0.0.1  TCP 66 [TCP Dup ACK 16#1] 53302 > 9999 [ACK] Seq=6 Ack=1 Len=0
 26.491  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
 31.599  127.0.0.1 -> 127.0.0.1  TCP 74 9999 > 53302 [SYN, ACK] Seq=0 Ack=1 Len=0
 31.599  127.0.0.1 -> 127.0.0.1  TCP 66 [TCP Dup ACK 19#1] 53302 > 9999 [ACK] Seq=6 Ack=1 Len=0
 53.179  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
106.491  127.0.0.1 -> 127.0.0.1  TCP 71 [TCP Retransmission] 53302 > 9999 [PSH, ACK] Seq=1 Ack=1 Len=5
106.491  127.0.0.1 -> 127.0.0.1  TCP 54 9999 > 53302 [RST] Seq=1 Len=0
```

由于客户端上的TCP实现获得多个`SYN/ACK`分组，因此它将假设`ACK`分组丢失并重新发送（请参阅上面跟踪中带有`TCP Dup ACK`的行）。若服务器端的应用程序在达到最大`SYN/ACK`重试次数之前减少了backlog（即从accept队列中消费了一个entry），那么TCP实现最终将处理其中一个重复的`ACK`，转换状态从`SYN RECEIVED`到`ESTABLISHED`的connection，并将其添加到accept队列。否则，客户端最终将获得`RST`分组（如上面显示的示例）。

上述数据包跟踪还显示了此行为的另一个有趣方面。从客户端的角度来看，在接收到第一个`SYN/ACK`分组后，connection将处于`ESTABLISHED`状态。如果它发送数据（不先从服务器等待数据），那么也将重传该数据。幸运的是，[TCP慢启动](http://en.wikipedia.org/wiki/Slow-start)应该限制在此阶段发送的段数（the number of segments sent）。

另一方面，如果客户端首先等待来自服务器的数据并且服务器永远不会减少backlog，那么最终结果是在客户端，连接处于`ESTABLISHED`状态，而在服务器端，connection被视为`CLOSED`。这意味着我们最终会建立[半开连接](http://en.wikipedia.org/wiki/Half-open_connection)！

还有一个方面我们尚未讨论。来自`listen系统调用`的手册页的引用表明每个`SYN`分组都会导致一个connection被添加到`SYN`队列（除非该队列已满）。事实并非如此。原因在`net/ipv4/tcp_ipv4.c`的`tcp_v4_conn_request`方法（处理`SYN`分组）的如下代码中：

```c
/* Accept backlog 已满。如果我们已经在`SYN`队列中排队了足够的热条目，则删除请求。它比使用指数增加超时的openreqs堵塞`SYN`队列更好。
*/
if (sk_acceptq_is_full(sk) && inet_csk_reqsk_queue_young(sk) > 1) {
        NET_INC_STATS_BH(sock_net(sk), LINUX_MIB_LISTENOVERFLOWS);
        goto drop;
}
```

这意味着若accept队列已满，则内核将对接受`SYN`分组的速率施加限制。若收到太多的`SYN`分组，其中一些将被丢弃。在这种情况下，由客户端重试发送`SYN`分组，我们最终得到的行为与BSD派生的实现相同。

最后，让我们试着了解为什么Linux的设计选择优于传统的BSD实现。Stevens提出以下有趣的观点：

> The backlog can be reached if the completed connection queue fills (i.e., the server process or the server host is so busy that the process cannot call accept fast enough to take the completed entries off the queue) or if the incomplete connection queue fills. The latter is the problem that HTTP servers face, when the round-trip time between the client and server is long, compared to the arrival rate of new connection requests, because a new SYN occupies an entry on this queue for one round-trip time. […]

> The completed connection queue is almost always empty because when an entry is placed on this queue, the server’s call to accept returns, and the server takes the completed connection off the queue.

Stevens建议的解决方案只是增加backlog。这样做的问题在于，它假定应用程序需要调整backlog，不仅要考虑它如何处理新建立的传入连接（incoming connection），还要考虑到诸如往返时间（round-trip time）等流量特性（traffic characteristics）的功能。Linux中的实现有效地区分了这两个问题：应用程序只负责调整backlog，以便它可以足够快地调用`accept系统调用`以避免填充accept队列），然后，系统管理员可以根据流量特征调整`/proc/sys/net/ipv4/tcp_max_syn_backlog`。

