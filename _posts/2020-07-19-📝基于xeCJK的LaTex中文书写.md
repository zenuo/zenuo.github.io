---
layout: post
tag: LaTex
---

### 1 安装环境

首先，您需要在本地安装一个TeX发行版，您可以选择大而全的[MacTeX](https://tug.org/mactex/mactex-download.html)，为了节省本地空间，此处选择更小的发行版[BasicTeX](http://tug.org/cgi-bin/mactex-download/BasicTeX.pkg)；若网速过慢，你可以选择国内院校提供的镜像，比如[tuna（清华大学开源软件镜像站）](https://mirrors.tuna.tsinghua.edu.cn/ctan/systems/mac/mactex/)；下载完成之后，运行程序，一路`continue`即可：

![63e8f062441750449249892f.png](/assets/img/63e8f062441750449249892f.png)

其次，使用`tlmgr(the native TeX Live Manager)`安装`ctex`和`xecjk`：

``` bash
$ sudo tlmgr install ctex xecjk
```

### 2 Hello World

创建一个纯文本文件`hello_world.tex`，内容为：

``` tex
\documentclass{article}
\usepackage{xeCJK}
\setCJKmainfont{STSong}
\begin{document}
Hello World!\\
天地玄黃宇宙洪荒日月盈仄
\end{document}
```

保存文件，使用`xelatex`命令，输出pdf文件：

``` bash
$ xelatex hello_world.tex
```

如果不出问题的话，输出的`hello_world.pdf`文件将会是：

![9a2750e5d182f628673ee7f6.png](/assets/img/9a2750e5d182f628673ee7f6.png)

### 3 参考

1. [** Smaller Download **](https://tug.org/mactex/morepackages.html)
2. [全面总结如何在 LaTeX 中使用中文 (2020 最新版) - jdhao's blog](https://jdhao.github.io/2018/03/29/latex-chinese.zh/)
3. [Include Chinese characters into article in Xelatex](https://tex.stackexchange.com/questions/376420/include-chinese-characters-into-article-in-xelatex)
