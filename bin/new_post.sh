#!/usr/bin/env bash

cd `dirname $0`
date=`date +%Y-%m-%d`
echo '---
layout: post
---' > "../_posts/$date-$@"

