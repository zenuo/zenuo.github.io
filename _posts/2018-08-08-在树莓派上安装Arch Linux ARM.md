---
layout: post
---

> 来自https://archlinuxarm.org/platforms/armv6/raspberry-pi

请将下面指令中的`sdX`替换为SD卡在您电脑中的设备名称。

1. 使用fdisk为SD卡分区:
```bash
# fdisk /dev/sdX
```
2. 在fdisk的提示符中，删除原有的分区，然后新建分区：
    1. 按`o`，清除此设备上所有的分区；
    2. 按`p`来列出所有分区，当前设备应该没有任何分区存在；
    3. 按`n`，然后按`p`（主分区），然后按`1`（设备上第一个分区），然后按`回车`键接受默认的第一个扇区，然后为最后一个扇区输入`+100M`；
    4. 按`t`，然后按`c`设置第一个分区类型为`W95 FAT32(LBA)`；
    5. 按`n`，然后按`p`（主分区），按`2`（设备上第二个分区），然后按两次`回车`来接受默认的第一个和最后一个扇区；
    6. 按`w`，写入分区表后退出；
3. 创建FAT文件系统并装载
```bash
# mkfs.vfat /dev/sdX1
# mkdir boot
# mount /dev/sdX1 boot
```
4. 创建ext4文件系统并装载:
```bash
# mkfs.ext4 /dev/sdX2
# mkdir root
# mount /dev/sdX2 root
```
5. 下载系统镜像文件，并且提取到`root`文件系统（注，作为`root用户`，而不是通过`sudo`）: 
```bash
# wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz
# bsdtar -xpf ArchLinuxARM-rpi-latest.tar.gz -C root
# sync # 此命令比较耗时
```
6. 移动boot文件到第一个分区：
```bash
# mv root/boot/* boot
```
7. 卸载两个分区
```bash
# umount boot root
```
8. 将SD卡插入到树莓派，连接以太网，并且连接电源
9. 使用`串行控制台(serial console)`或者`SSH`连接
- 使用默认用户`alarm`，密码`alarm`
- `root`用户的密码默认是`root`
> 注：为了安全，请强化用户密码
10. 初始化pacman密钥环并填充Arch Linux ARM包签名密钥:
```bash
# pacman-key --init
# pacman-key --populate archlinuxarm
```

至此，树莓派安装完成，您可以使用包管理器`pacman`安装sudo/ufw等工具，强化安全，也可以当作一个家用的服务器，祝玩得开心🥳~
