#!/bin/bash
git add . && \
git commit -m "commit" && \
git push && \
jekyll build && \
cd _site && \
git add . && \
git commit -m "commit" && \
git push && \
cd .. && \
echo "$(date +%Y年%m月%d日%H时%M分%S秒) committed"

