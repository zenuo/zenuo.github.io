---
title: "MySQL的mysqldump例子"
date: 2018-05-27T19:23:13+08:00
categories: ["tech"]
---


```bash
$ mysqldump \
--result-file=SQL_FILE_PATH \
--complete-insert SCHEMA_NAME [TABLE_NAME] \
-uYOUR_USERNAME \
-pYOUR_PASSWORD \
--host=HOST \
--port=PORT
```