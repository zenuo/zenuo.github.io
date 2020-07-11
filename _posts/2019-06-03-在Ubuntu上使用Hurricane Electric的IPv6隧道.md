---
layout: post
---

当我们的主机没有全局IPv6地址时，我们可以使用`IPv6隧道`为主机提供IPv6地址；下面，我们来尝试一下在Ubuntu使用Hurricane Electric提供的隧道服务。

## 创建隧道

登录[Hurricane Electric Free IPv6 Tunnel Broker](https://tunnelbroker.net)，点击`Create Regular Tunnel`：

![0602d3a894e1727d083d7b46.png](/assets/img/0602d3a894e1727d083d7b46.png)

在`IPv4 Endpoint (Your side)`输入您的主机的IPv4地址，例如：

![3954410ce25a87beef3a62ea.png](/assets/img/3954410ce25a87beef3a62ea.png)

在`Available Tunnel Servers`中选择一台可用的隧道服务器：

![a31a0692200f6154b6a20b52.png](/assets/img/a31a0692200f6154b6a20b52.png)

此处选择了一台位于加拿大🇨🇦多伦多的一台服务器；点击页面底部的`Create Tunnel`：

![dca4a10da46ba16615408789.png](/assets/img/dca4a10da46ba16615408789.png)

待创建完成，跳转至`Tunnel Details`页面：

![2173bcae6ba24621d1980851.png](/assets/img/2173bcae6ba24621d1980851.png)

## 配置服务器

点击`Example Configurations`，选择`Debian/Ubuntu`，会给出配置内容，如图：

![70752184c64a602d7e85f778.png](/assets/img/70752184c64a602d7e85f778.png)

编辑**`/etc/network/interfaces`**，复制粘贴配置内容：

```conf
auto he-ipv6
iface he-ipv6 inet6 v4tunnel
        address {Placeholder}
        netmask 64
        endpoint {Placeholder}
        local {Placeholder}
        ttl 255
        gateway {Placeholder}
```

> 注：这里的配置内容已做脱敏处理🐹，请不要直接复制粘贴

然后，我们需要启用IPv6，编辑**`/etc/sysctl.conf`**，设置如下三项：

```conf
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.default.disable_ipv6=0
net.ipv6.conf.lo.disable_ipv6=0
```

重启主机，待重启完成即可。

## 参考

- [IPv6 Tunnel Broker](https://www.tunnelbroker.net/)
- [Tunneled IPv6](https://wiki.ubuntu.com/IPv6#Tunneled_IPv6)
- [阿里云 Ubuntu 支持 IPv6 的完整步骤](https://jiandanxinli.github.io/2016-08-06.html)
