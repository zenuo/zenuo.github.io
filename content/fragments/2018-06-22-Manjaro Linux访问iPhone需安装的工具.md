---
title: "Manjaro Linux访问iPhone需安装的工具"
date: 2018-06-22T19:23:13+08:00
categories: ["tech"]
---

## libimobiledevice简介

> libimobiledevice是一个跨平台的软件库，可协议支持iPhone®，iPodTouch®，iPad®和AppleTV®设备。 与其他项目不同，它不依赖于使用任何现有的专有库并且不需要越狱。 它允许其他软件轻松访问设备的文件系统，检索有关设备及其内部的信息，备份/恢复设备，管理SpringBoard®图标，管理已安装的应用程序，检索地址簿/日历/笔记和书签以及（使用libgpod）同步音乐 和视频到设备。 该库自2007年8月开始开发，使Linux桌面支持这些设备。

以上摘自[libimobiledevice项目官网](http://www.libimobiledevice.org/)

## 使用pacman安装

执行如下命令：

```
$ sudo pacman -Syy
$ sudo pacman -S ifuse usbmuxd libplist libimobiledevice
```

## 参考

 - https://forum.manjaro.org/t/how-to-access-an-iphone-with-manjaro/3768/4
 - http://www.libimobiledevice.org/
