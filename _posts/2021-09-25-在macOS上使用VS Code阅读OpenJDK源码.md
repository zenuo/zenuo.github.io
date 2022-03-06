---
layout: single
toc: true
---

## 1 本地环境

- 操作系统：macOS Big Sur 11.5.2
- XCode: 13A5155e
- JDK: openjdk version "11.0.9"
- VS Code: 1.60.2

## 2 下载OpenJDK工程

创建一个`不含用户名相关`（建议）的路径，例如`/opt/source`，将OpenJDK 11的工程克隆至本地：

```
cd /opt/source
```

将`openjdk/jdk11u`克隆到本地，🐢需要良好的网络环境，所以使用本地的代理；若不需要代理请忽略第一行：

```
https_proxy=socks5://localhost:1080 \
git clone https://github.com/openjdk/jdk11u.git
```

☕️建议喝杯水等会儿，等克隆完进入下个步骤。

## 3 为构建做配置

对于文件数量大、结构复杂的工程，一般会引入构建工具，来实现日常的开发、发布流程的标准化，如[GNU Make](https://www.gnu.org/software/make/)、[Apache Maven](https://maven.apache.org/)等，OpenJDK 11亦然。

对于开发阶段，要求构建耗时短（不进行程度高的优化）、构建结果便于调试（debug）、运行速度可以不那么快；对于发布阶段，要求可执行文件运行速度快，构建耗时可以稍微长点儿。OpenJDK的构建支持通过配置（configure脚本）参数`--with-debug-level=<level>`来指定构建结果的调试级别，来实现不同阶段对构建结果的debug支持程度。

由于本文介绍的是搭建阅读代码环境，所以是开发阶段，执行：

```
cd /opt/source/jdk11u
bash ./configure \
    #指定本地的JDK，对版本有要求 \
    --with-boot-jdk=/opt/app/jdk-11.0.9+11/Contents/Home \
    #若代码中存在编译时警告，使编译继续进行，不当做异常 \
    --disable-warnings-as-errors \
    #指定调试等级 \
    --with-debug-level=slowdebug \
    #调试符号将在构建过程中生成，它们将被保存在生成的二进制文件中。 \
    --with-native-debug-symbols=internal
```

若本地环境满足构建需求，脚本正常结束，否则会有报错信息。

## 4 构建

这个步骤需要大量的CPU、内存资源，建议关掉不需要的程序，若是笔电建议接上电源（当然，壕机器请随意😎）。

执行：

```
CONF=macosx-x86_64-normal-server-slowdebug make all
```

过程需要一些时间，☕️☕️☕️多喝几杯水，等完成再进入下个步骤。

## 5 生成VS Code工作空间

根据[doc/ide](https://github.com/openjdk/jdk11u/blob/master/doc/ide.md)的介绍，OpenJDK 11的构建系统支持了生成[VS Code](https://code.visualstudio.com/)工作空间，通过这种方式来支持了IDE的标准化，大项目就是不一样👏。

执行：

```
CONF=macosx-x86_64-normal-server-slowdebug make vscode-project
```

完成后，你能看到文件`/opt/source/jdk11u/build/macosx-x86_64-normal-server-slowdebug/jdk.code-workspace`

## 6 使用VS Code打开工程

在打开工程前，需要安装插件[C/C++](https://github.com/microsoft/vscode-cpptools)：

![823311c0ba209e392d1434b9.png](/assets/img/823311c0ba209e392d1434b9.png)

安装完成之后，通过`File -> Open Workspace...`打开文件`/opt/source/jdk11u/build/macosx-x86_64-normal-server-slowdebug/jdk.code-workspace`。

## 7 断点调试

打开文件`/opt/source/jdk11u/src/java.base/share/native/libjli/java.c`，在方法`JavaMain`的第一行代码打上断点，如图的394行：

![88a9a5b1f309789a78d6deb2.jpg](/assets/img/88a9a5b1f309789a78d6deb2.jpg)

在侧边栏的`Run and Debug`中选择`java (Build artifacts)`：

![ad6eec34a947569280539b6c.png](/assets/img/ad6eec34a947569280539b6c.png)

点击绿色三角形按钮，开始运行：

![f5d34f285e85191b06c47f5b.png](/assets/img/f5d34f285e85191b06c47f5b.png)

等待程序运行到断点：

![ba6eac21ed89a7b59e5940bd.png](/assets/img/ba6eac21ed89a7b59e5940bd.png)

## 8 参考

- [win10上构建并调试openjdk 11](https://last2win.com/2021/06/13/build-jdk/)
- [doc/building.md](https://github.com/openjdk/jdk11u/blob/master/doc/building.md)
