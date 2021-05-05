#!/usr/bin/env bash
git add . && \
git commit -m $(openssl rand -hex 8) && \
git push
# bundle exec jekyll build 
