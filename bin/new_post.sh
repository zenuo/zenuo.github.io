#!/usr/bin/env bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: "$0" <new post name>"
    exit 1
fi

cd `dirname $0`
date=`date +%Y-%m-%d`
newFilePath="../content/posts/$date-$@.md"
echo "---
title: "$@"
date: ${date}T00:00:00+0800
tags: ["tech"]
---
" > "$newFilePath"
echo "new post created: '$(pwd)/$newFilePath'"
exit 0
