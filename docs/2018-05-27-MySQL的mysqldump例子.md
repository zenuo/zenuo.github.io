---
layout: single
toc: true
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