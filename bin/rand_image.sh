#!/usr/bin/env bash

# 目标路径
image_path='/assets/img/'

# 移动指定的图片到文件夹，并重命名为随机字符串

# 检查参数
if [[ "$#" -ne 1 ]]; then
    echo "usage: "$0" <image_file_path>"
    exit 1
fi

# 切换到本脚本所在的文件夹
cd `dirname "$0"`
# 文件名
filename=`basename -- "$1"`
# 拓展名
extension=${filename##*.}
# 随机字符串
rand=`openssl rand -hex 12`

# 将参数指定的文件移动到图片文件夹，并重命名
mv "$1" ../assets/img/$rand.$extension && \
echo ![$rand.$extension]\($image_path$rand.$extension\) && \

# 若xclip存在（Linux系统）
if [ -x "$(command -v xclip)" ]; then
  echo ![$rand.$extension]\($image_path$rand.$extension\) | xclip -sel clip
# 若pbcopy存在（macOS系统）
elif [ -x "$(command -v pbcopy)" ]; then
  echo ![$rand.$extension]\($image_path$rand.$extension\) | pbcopy
fi
