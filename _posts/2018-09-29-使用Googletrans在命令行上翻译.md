---
layout: post
---

## googletrans介绍

[googletrans](https://pypi.org/project/googletrans/)是一个免费、无限制的Python库，实现了`Google Translate API`，使用`Google Translate Ajax API`进行语言检测和翻译。

## 安装

```bash
$ git clone https://github.com/BoseCorp/py-googletrans.git
$ cd ./py-googletrans
$ sudo python3 setup.py install
```

## 脚本内容

```python
#!/usr/bin/env python3

from sys import argv
from googletrans import Translator

t = Translator(service_urls=['translate.google.cn'])
if argv[1] == '-r':
    r = t.translate(' '.join(argv[2:]), dest='en')
else:
    r = t.translate(' '.join(argv[1:]), dest='zh-CN')
print(r.text)
```

## 示例

> 您可以将脚本所在路径添加到`PATH`环境变量中

```bash
$ ./gt.py "In view of these constraints, it is clear that there is a need for a file delivery service capable of transferring files to and from mass memory located in the space segment. Such a capability must not only operate under the constraints associated with space data communication, but it must also be applicable to the diverse range of mission configurations ranging from single low earth orbiting spacecraft to complex networks of relays, orbiters, and landers."
鉴于这些约束，显然需要一种能够将文件传送到位于空间段中的大容量存储器和从大容量存储器传送文件的文件传送服务。这种能力不仅必须在与空间数据通信相关的限制下运行，而且还必须适用于从单个低地球轨道航天器到复杂的继电器网络，轨道器和着陆器的各种任务配置。
```

## 参考

- https://pypi.org/project/googletrans/
- https://github.com/BoseCorp/py-googletrans
