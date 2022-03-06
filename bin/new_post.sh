#!/usr/bin/env bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: "$0" <new post name>"
    exit 1
fi

cd `dirname $0`
date=`date +%Y-%m-%d`
newFilePath="../_posts/$date-$@.md"
echo '---
layout: single
toc: true
---
' > "$newFilePath"
echo "new post created: '$(pwd)/$newFilePath'"
exit 0
