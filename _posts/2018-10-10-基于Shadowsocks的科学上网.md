---
layout: post
---

以下是维基百科对`Shadowsocks`的描述：

> Shadowsocks is a free and open-source encrypted proxy project, widely used inmainland China to circumvent Internet censorship. It was created in 2012 by a Chinese programmer named "clowwindy", and multiple implementations of the protocol have been made available since. Typically, the client software will open a socks5 proxy on the machine it is run, which internet traffic can then be directed towards, similarly to an SSH tunnel. Unlike an SSH tunnel, shadowsocks can also proxy UDP traffic.

本文内容为软件的部署与操作，分为`服务端`与`客户端`两部分。

# 1 服务端

> 本部分介绍在Ubuntu上的步骤，其他操作系统可以此为参考。

本步骤中，您需要：

- 一台不受GFW影响的主机（可以到各大VPS厂商购买）

- 命令行基础

## 1.1 安装python3和pip

执行Bash命令：

``` bash
sudo apt update
sudo apt install python3 python3-pip
```

## 1.2 安装shadowsocks

> shadowsocks服务端的Python实现托管于[shadowsocks/shadowsocks](https://github.com/shadowsocks/shadowsocks/tree/master)

使用pip安装shadowsocks服务端，执行Bash命令：

``` bash
sudo pip3 install git+https://github.com/shadowsocks/shadowsocks.git@master
```

## 1.3 配置文件

在您的home目录里，新建`ss`目录，将shadowsocks的`配置文件`和`日志文件`放置在其中；执行Bash命令：

``` bash
mkdir ~/ss
cd ss
```

使用你喜欢的文本编辑器，创建配置文件`config.json`，此处实例使用nano；执行Bash命令：

``` bash
nano config.json
```

粘贴如下内容，并根据您的喜好设置：

``` json
{
    "server_port":8388,
    "password":"your_password",
    "method":"aes-256-cfb"
}
```

字段说明：

|名称|说明|
|:-:|:-:|
|server_port|服务端监听的端口|
|password|密码|
|method|加密方法，请查看[Encryption](https://github.com/shadowsocks/shadowsocks/wiki/Encryption)|

> 更多说明请查看[wiki](https://github.com/shadowsocks/shadowsocks/wiki)

## 1.5 运行

在后台运行shadowsocks，并将日志写入文件`~/ss/log`，执行Bash命令：

``` bash
ssserver -c ~/ss/config.json --log-file ~/ss/log --pid-file ~/ss/pid -d start
```

Bash会话记录如下：

[![asciicast](https://asciinema.org/a/Pl6tGzRIfOCuTlRU5xCjnoVc3.png)](https://asciinema.org/a/Pl6tGzRIfOCuTlRU5xCjnoVc3)

## 1.4 防火墙开放shadowsocks端口

在`1.3 配置文件`中的示例配置文件中，我们设置了shadowsocks监听`8388`端口，如果您的主机开启了防火墙，则我们需要开放这个端口；此处假设防火墙软件为`ufw`，执行Bash：

``` bash
sudo ufw allow 8388
```

# 2 客户端

本部分依次介绍在Android / macOS / [Manjaro Linux](https://manjaro.org/) 操作系统上的shadowsocks客户端使用。

## 2.1 Android

> shadowsocks的Android客户端托管于[shadowsocks/shadowsocks-android](https://github.com/shadowsocks/shadowsocks-android)

首先，在`Releases`页面下载您的CPU架构对应的安装包，截图如下：

![shadowsocks-android Releases](/assets/img/4bbec1cf000d8a274cb3a762.png)

> 关于Android的CPU架构，摘自[What is armeabi and why they use it?](https://stackoverflow.com/questions/23042175/what-is-armeabi-and-why-they-use-it)的一个[回答](https://stackoverflow.com/a/23042278)：
Android设备有CPU。 其中许多CPU基于ARM架构，有些基于x86，还有一些基于MIPS等其他东西。
一些Android应用程序使用Native Development Kit（NDK）创建C / C++代码以链接到他们的应用程序。 需要针对特定的CPU架构编译C / C++代码。 NDK将为每个体系结构编译的C / C++代码版本放入特定于体系结构的目录中。 其中一个目录是armeabi /，它用于通用ARM CPU。 还有armeabi-v7 /（对于ARM v7兼容的CPU），x86 /（对于x86 CPU）等。（来自谷歌翻译）

下载并安装后，打开程序，默认页面为`配置文件`，截图如下：

![Android初始化截图](/assets/img/f951332f54ea98bc328401cd.png)

> 我们假定您的主机IP地址为`6.6.6.6`

点击下方截图中红框所示的`铅笔`按钮：

![铅笔](/assets/img/ebb0f61599cfb9aab3395841.png)

根据`1.3 配置文件`中的示例配置文件，修改`服务器配置`中的项，截图如下，红框所示：

![服务器配置](/assets/img/bfae9e0beb4d525ff3e65ee1.png)

继续修改`功能设置`，`路由`设置为`GFW列表`（在您理解其他选项时，可以选择其他选项），其余选项保持默认，截图如下：

![功能设置](/assets/img/a218fca96b9fa5d259faf181.jpeg)

其余选项保持默认，点击右上角的`勾`按钮，保存修改，截图如下：

![保存修改](/assets/img/24aa66cb9c96ccdd6bdc1397.jpeg)

点击右下角的`小飞机`，以连接服务器，首次会弹出截图所示对话框；

![网路连接请求](/assets/img/4a08fe79af81a243a3f3b19b.jpeg)

请打开您的浏览器，访问`https://google.com`以测试是否能科学上网，若您的操作正确，则可以访问。

## 2.2 macOS

> shadowsocks的macOS端托管于[shadowsocks/ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG)

首先，到[Releases](https://github.com/shadowsocks/ShadowsocksX-NG/releases)页面下载程序，页面截图如下：

![Releases](/assets/img/5682cd985ae8f0b65c1c5026.png)

下载完成后，由页面上的[sha256和](https://176.122.157.73:3457/zh/SHA-2)，校验下载的文件是否相同；若不是，请尝试重新下载；若是，拖拽至`应用程序`中，双击运行，会在`菜单栏`中显示灰色的`小飞机`，截图如下：

![灰色小飞机](/assets/img/df44e55c6fa45cce51c34611.png)

单击小飞机，现实菜单，截图如下：

![菜单](/assets/img/158f28d056ff2ba58109cfff.png)

点击`服务器`>`服务器设置`>`+`，按照`您的服务器配置情况`填写数据项，点击`确定`，再次进入`服务器设置`，截图如下：

![服务器设置](/assets/img/ea338fdadb00ac196ee80271.png)

您可能已经观察到，Shadowsocks默认选择了`PAC自动模式`，若您刚接触此软件，请保留此设置，截图如下：

![PAC自动模式](/assets/img/eddf799938980012c5f15b9b.png)

点击菜单栏的小飞机>`打开 Shadowsocks`，小飞机由`灰色`变为`黑色`，截图如下：

![黑色小飞机](/assets/img/76be647b40baf2f0ea30c453.png)

请打开您的浏览器，访问`https://google.com`以测试是否能科学上网，若您的操作正确，则可以访问。

## 2.3 Manjaro Linux

> 分为`Shadowsocks客户端`和`浏览器插件`两部分

### 2.3.1 Shadowsocks客户端

> [shadowsocks/shadowsocks-qt5](https://github.com/shadowsocks/shadowsocks-qt5/)是一个跨平台的客户端。

在Linux操作系统上，我们通过包管理器安装shadowsocks-qt5，打开终端，执行Bash命令：

```bash
sudo pacman -Syy
sudo pacman -S shadowsocks-qt5
```

安装完成后，打开shadowsocks-qt5，截图如下：

![shadowsocks-qt5截图](/assets/img/6dfba8e2dbaf17a04ab234a0.png)

点击菜单`Connection`>`Add`>`Manually`，截图如下：

![Manually](/assets/img/42312a33d953f5cb2f25a985.png)

按照`您的服务器配置情况`填写数据项，截图如下：

![服务器配置](/assets/img/f8cb05318c5e44c0d012d919.png)

点击`OK`，选中刚刚创建的服务器项，点击菜单`Connection`>`Connect`，若您的操作正确，则服务器项的`Status`为`Connected`。

### 2.3.2 浏览器插件

> [FelisCatus/SwitchyOmega](https://github.com/FelisCatus/SwitchyOmega)项目提供了`Chrome(或者Chromium)`和`Firefox`的代理插件，本部分演示在Chrome浏览器的操作。

首先，到[Releases](https://github.com/FelisCatus/SwitchyOmega/releases)下载[SwitchyOmega_Chromium.crx](https://github.com/FelisCatus/SwitchyOmega/releases/download/v2.5.20/SwitchyOmega_Chromium.crx)安装包；在Chrome地址栏输入`chrome://extensions/`并回车，进入拓展程序界面，点击右上角的`开发者模式`，将下载好的SwitchyOmega_Chromium.crx文件拖拽到此界面，安装；

安装完成后，自动打开设置界面，您可以跟随教程学习；完成后，点击`PROFILES`>`proxy`，根据`2.3.1 Shadowsocks客户端`的配置来设置`Proxy servers`，`Protocol`选择`SOCKS5`，`Server`设置`127.0.0.1`，`Port`设置`1080`，点击`ACTIONS`>`Apply changes`，以保存设置，截图如下：

![设置Proxy servers](/assets/img/3c718b8e86081da611540e26.png)

点击`地址栏`右边的`小黑圈`，选择`proxy`，访问`https://google.com`，若您的操作正确，则可以访问；

> `proxy`模式下，所有流量都通过代理服务器，您可以使用`auto switch`模式，自动添加代理规则；更多信息请查看[wiki](https://github.com/FelisCatus/SwitchyOmega/wiki)