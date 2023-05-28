#!/usr/bin/env bash

if [[ "$#" -ne 1 ]]; then
    echo "usage: "$0" <new post name>"
    exit 1
fi

cd `dirname $0`
date=`date +%Y-%m-%d`
newFilePath="../content/$date-$@.md"
echo '---
title: ""
date: date
categories: ["tech"]
---
' > "$newFilePath"
echo "new post created: '$(pwd)/$newFilePath'"
exit 0
