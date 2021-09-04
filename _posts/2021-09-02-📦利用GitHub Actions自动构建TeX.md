---
layout: post
---

笔者维护的一些TeX文档（简历等）通常是在`安装好TeX发行版`的主机上进行编辑和构建，当无法访问这些主机的时候，该怎么操作呢？🤔

联想到GitHub的Actions功能，可以用来做CI/CD，也许有戏。通过搜索，找到了[xu-cheng/latex-action](https://github.com/xu-cheng/latex-action)，可以达到通过`git push`操作来触发构建，并将构建的pdf文件打包放置到`Workflow`的`Artifacts`中。

假设需要被编译的TeX文件的相对路径为`resume.tex`，编译器是`XeLaTeX`，那么可以用下面的workflow描述文件来达到目的：

```yml
name: Build LaTeX document
on: [push]
jobs:
  build_latex:
    runs-on: ubuntu-latest
    steps:
      - name: Set up Git repository
        uses: actions/checkout@v2
      - name: Compile LaTeX document
        uses: xu-cheng/latex-action@v2
        with:
          root_file: resume.tex
          pre_compile: "fc-list :lang=zh"
          latexmk_use_xelatex: true
      - uses: actions/upload-artifact@v2
        with:
          name: PDF
          path: resume.pdf
```

放置到仓库的`.github/workflows/`路径，再出发push即可。

