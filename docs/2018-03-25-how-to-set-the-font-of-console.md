---
layout: single
toc: true
---
## 1 查看可用的字体
```
$ cd /usr/share/kbd/consolefonts
$ ls -l
```

在我电脑上的输出如下：
```
total 1864
-rw-r--r-- 1 root root  3019 Jan 21  2017 161.cp.gz
-rw-r--r-- 1 root root  3086 Jan 21  2017 162.cp.gz
-rw-r--r-- 1 root root  3069 Jan 21  2017 163.cp.gz
-rw-r--r-- 1 root root  3136 Jan 21  2017 164.cp.gz
-rw-r--r-- 1 root root  3247 Jan 21  2017 165.cp.gz
-rw-r--r-- 1 root root  2948 Jan 21  2017 737.cp.gz
-rw-r--r-- 1 root root  2914 Jan 21  2017 880.cp.gz
-rw-r--r-- 1 root root  2759 Jan 21  2017 928.cp.gz
-rw-r--r-- 1 root root  2159 Jan 21  2017 972.cp.gz
...
```
## 2 设置
执行如下命令，设置`ter-v18n`为终端字体，若设置成功，则立即显示为新的字体；
```
$ sudo setfont ter-v18n.psf
```

