---
title: "🧰EasyConnect in Dokcer"
date: 2021-05-01T19:23:13+08:00
categories: ["tech"]
---

[Sangfor EasyConnect](https://www.sangfor.com/en/products/infrastructure/easyconnect)是一款专有的VPN解决方案，官方支持多种平台的客户端；但该软件目前存在以下的几种行为：

1. 配置一个开机自动启动的守护进程`EasyMonitor`
2. 安装CA根证书

为了避免上述两种情况对本地系统造成不良影响，尝试寻找方法将EasyConnect运行在受控的容器内。所幸在[Hagb/docker-easyconnect](https://github.com/Hagb/docker-easyconnect)找到了，该仓库介绍了一种在Docker内运行EasyConnect的方案。通过该方案，在此记录下我的实践过程。

## 1 运行容器

> 在`Docker宿主机`为[Alpine Linux](https://alpinelinux.org/)时，映射到`Docker宿主机`的端口，无法在宿主机的外部网络（例如宿主机所在的局域网）访问，但可以在宿主机本地访问；

创建文件用于保存登录凭证，以实现auto login：

```
$ touch ~/.easyconn
```

从Docker镜像`hagb/docker-easyconnect:cli`创建一个名称为`easyconnect`的容器，并且将`容器的1080端口`映射到`Docker宿主机的1080端口`（1080只是一个示例值，可以是其他的；敲黑板，后续会用到）：

```
$ docker run --name easyconnect --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -e EC_VER=7.6.8 -e EXIT=1 -p 1080:1080 hagb/docker-easyconnect:cli
```

根据提示输入`服务器URL`、`用户名`、`密码`。

注意服务器URL末尾不需要反斜线（`/`），例如正确的`https://vpn_host`。

如果成功登入，则会提示：

```
user "xx" login successfully!
```

## 2 浏览器over proxy

1. 浏览器运行时动态配置代理，可以通过[SwitchyOmega](https://github.com/FelisCatus/SwitchyOmega)来实现，须将Proxy设置为`Docker宿主机的1080端口`

2. 浏览器启动时指定代理，若您是使用`Chromium`相关（比如Chrome），则可通过命令行启动：

```
$ chromium —proxy-server=socks5://${Docker宿主机IP}:1080
```

## 3 ssh over proxy

> 若您是使用Arch Linux，需要安装openbsd-netcat，而不是gnu-netcat

编辑ssh配置文件`~/.ssh/config`，添加内容：

```
Host 10.1.*
    ProxyCommand /usr/bin/nc -x ${Docker宿主机IP}:1080 %h %p
```

使得在通过ssh访问匹配`10.1.*`（仅仅是示例，需要根据您的实际使用情况调整）的主机时，通过代理`${Docker宿主机IP}:1080`

## 4 git over proxy

分为两种情况：

1. 若git仓库的remote是`ssh`协议，编辑ssh配置文件`~/.ssh/config`，添加内容：

    ```
    Host ${git仓库域名}
        ProxyCommand /usr/bin/nc -x ${Docker宿主机IP}:1080 %h %p
    ```

2. 若git仓库的remote是`http`或者`https`协议，那么在与remote交互时，为git命令指定变量`http_proxy`，例如：

    ```
    $ https_proxy=socks5://localhost:1080 git clone http://${git仓库域名}/x/x.git
    ```

## 5 MySQL client over proxy

因为[原生MySQL client](https://dev.mysql.com/doc/refman/8.0/en/mysql.html)不支持socks5代理，可通过其他客户端来达到目的；例如[mycli](https://www.mycli.net/)，但mycli目前没有支持socks5代理，所以也需要采取一些额外的措施。

因为mycli基于Python实现，故可通过[PySocks](https://pypi.org/project/PySocks/)来对整个标准库进行猴补丁(Monkey patch)，使所有的socket都通过一个代理建立。

假设您是通过brew安装的mycli，那么需要修改`/usr/local/bin/mycli`，添加内容：

```python
import socket
import socks

ip = '${Docker宿主机IP}'
port = 1080
socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, ip, port)
socket.socket = socks.socksocket
```

保存即可使用。

## 6 参考

1. https://zhuanlan.zhihu.com/p/259634641
2. https://www.sangfor.com/en/products/infrastructure/easyconnect
3. https://github.com/Hagb/docker-easyconnect
4. https://docs.docker.com/config/containers/container-networking/
5. https://superuser.com/questions/454210/how-can-i-use-ssh-with-a-socks-5-proxy
6. https://pypi.org/project/PySocks/
7. https://www.mycli.net/
8. https://dev.mysql.com/doc/refman/8.0/en/mysql.html

