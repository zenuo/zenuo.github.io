---
layout: single
toc: true
---

首先在Xcode上创建一个`Swift Package`，菜单是`File` / `New` / `Swift Package`：

![保存](/assets/img/9e9f613125350f50b735061e.jpg)

选择保存路径：

![7d3e86e2675b37316f5ba398.png](/assets/img/7d3e86e2675b37316f5ba398.png)

注意选择`Add to`：

![ab0e51ad624bc743d84f5cb4.jpg](/assets/img/ab0e51ad624bc743d84f5cb4.jpg)

1. 选择`Project` / `TARGETS`，然后选择需要使用我们刚才创建的`Swift Package`的`Target`，然后选择`General`栏，在`Framworks, Libraries, and Embedded Content`中添加Package，如图：

![481c498dde6159ffedb050a9.png](/assets/img/481c498dde6159ffedb050a9.png)

2. 选择`Build Phases`，在`Dependencies`添加Package，如图：

![724df656b457426f5f214ecd.png](/assets/img/724df656b457426f5f214ecd.png)

没有其他问题的话，您的Target能成功构建了。

## Reference

1. [Organizing Your Code with Local Packages](https://developer.apple.com/documentation/swift_packages/organizing_your_code_with_local_packages)
2. [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)
