---
title: "基于redsocks2和pf的macOS透明代理"
date: 2022-09-04T19:23:13+08:00
categories: ["tech"]
---


坑点：在[🧰EasyConnect in Dokcer](../2021-05-01-🧰EasyConnect in Dokcer/)中记录了在容器中运行Sangfor EasyConnect的步骤，并通过socks5代理来实现VPN使用，但这种方式具有一些局限性，仅对支持了socks5或http代理的程序有用。举一个不支持的例子：我在本地执行Java工程的单元测试时，单元测试中有访问zk的逻辑，尽管在JVM参数中添加了`-DsocksProxySet=true -DsocksProxyHost=alpine -DsocksProxyPort=1080`，但对访问zk底层的nio来说是无效的😢

还好在搜索到了这两篇文章，发现可以通过透明代理来支持这种场景：

- [macos使用redsocks做透明代理](https://luckypoem.blog.fc2.com/blog-entry-738.html)
- [macOS 透明代理配置](https://penglei.github.io/post/transparent_proxy_on_macosx/#_a_%E9%85%8D%E7%BD%AEpf_conf)

下面是我的操作步骤

# 1 编译、配置redsocks

```
$ wget https://github.com/HaoH/redsocks/archive/release-0.68.tar.gz # 下载源码
$ tar -zxvf redsocks-release-0.68.tar.gz # 解压缩
$ cd redsocks-release-0.68
```

在我的电脑环境中，按照源码包的代码构建的结果，运行时会报错：

```
1662282301.374137 err redsocks.c:693 redsocks_connect_relay(...) [192.168.0.103:54303->10.100.*.*:80]: red_connect_relay failed!!!: Protocol not available
1662282301.375292 err utils.c:154 red_prepare_relay(...) setsockopt: Protocol not available
```

可以看到报错在`utils.c:154`，经查阅[资料](https://git.kernel.dk/cgit/fio/commit/?id=8a768c2e725d6a527b904570949f6099c3f1434a)，此种报错可以被忽略，所以修改代码：

```
$ vim utils.c
```

将153至156行注释，忽略setsocketopt的报错：
```
        // if (error) {
        //     log_errno(LOG_ERR, "setsockopt");
        //     goto fail;
        // }
```

```
$ https_proxy=socks5://localhost:1080 make OSX_VERSION=master DISABLE_SHADOWSOCKS=true # 构建
$ vim redsocks.conf
```

内容如下：

```
base {
	log_debug = off;
	log_info = on;
	log = stderr;
	daemon = off;
	redirector = pf;
	reuseport = off;
}

redsocks {
    // redsocks的监听的地址和端口
	bind = "127.0.0.1:12345";
    // 代理的地址和端口
	relay = "192.168.17.128:1080";
	type = socks5;
	autoproxy = 0;
	timeout = 10;
}
```

# 2 配置pf

首先我们需要定义出需要转发到代理的cidr表，存放到文件`/opt/app/redsocks/forward_cidr.txt`，若需要转发`10.100.0.0/16`和`10.1.0.0/16`网段的IP到代理，内容如下：

```
10.100.0.0/16
10.1.0.0/16
```

编辑`/etc/pf.conf`，内容如下：

```
scrub-anchor "com.apple/*"

table <forward_cidr> persist file "/opt/app/redsocks/forward_cidr.txt"

nat-anchor "com.apple/*"

rdr-anchor "com.apple/*"
rdr pass on lo0 proto tcp from any to <forward_cidr> -> 127.0.0.1 port 12345

pass out route-to (lo0 127.0.0.1) proto tcp from any to <forward_cidr>

dummynet-anchor "com.apple/*"

anchor "com.apple/*"
load anchor "com.apple" from "/etc/pf.anchors/com.apple"
```

## 3 运行

启动的脚本内容如下：

```
# 启动pf
sudo sysctl -w net.inet.ip.forwarding=1
sudo pfctl -e
sudo pfctl -F all
sudo pfctl -f /etc/pf.conf

# 启动redsocks
sudo ./redsocks2 -c ./redsocks.conf
```

使用代理完成之后，你可以Ctrl+C关闭redsocks，然后用下面的脚本关闭pf:

```
# 关闭pf
sudo pfctl -d
sudo pfctl -F all
```
