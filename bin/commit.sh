#!/usr/bin/env bash
git add . && \
git commit -m "commit" && \
git push && \
bundle exec jekyll build && \
cd _site && \
git add . && \
git commit -m "commit" && \
git push && \
cd .. && \
echo "$(date +%Y-%m-%d-%H-%M-%S) committed"
