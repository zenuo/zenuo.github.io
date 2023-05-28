---
title: "📜读取MySQL的binlog"
date: 2020-07-12T19:23:13+08:00
categories: ["tech"]
---

配置`~/.my.cnf`，开启binlog:

```
[mysqld]
server-id=master-01
log-bin=mysql-bin
```

假设需要读取的binlog的文件是`mysql-bin.000001`，那么用下面命令即可根据开始结束时间输出可读日志：

``` bash
mysqlbinlog --base64-output=DECODE-ROWS \
-v \
--start-datetime='2020-07-12 21:33:10' \
--stop-datetime='2020-07-12 21:40:10' \
mysql-bin.000001
```

输出如下：

```
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=1*/;
/*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
DELIMITER /*!*/;
# at 4
#200712 21:24:18 server id 0  end_log_pos 123 CRC32 0x0d383a89 	Start: binlog v 4, server v 5.7.29-log created 200712 21:24:18 at startup
ROLLBACK/*!*/;
# at 672
#200712 21:33:44 server id 0  end_log_pos 737 CRC32 0x71a595ed 	Anonymous_GTID	last_committed=2	sequence_number=3	rbr_only=yes
/*!50718 SET TRANSACTION ISOLATION LEVEL READ COMMITTED*//*!*/;
SET @@SESSION.GTID_NEXT= 'ANONYMOUS'/*!*/;
# at 737
#200712 21:33:44 server id 0  end_log_pos 809 CRC32 0xb207c15c 	Query	thread_id=2	exec_time=0	error_code=0
SET TIMESTAMP=1594560824/*!*/;
SET @@session.pseudo_thread_id=2/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=0, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
SET @@session.sql_mode=1436549152/*!*/;
SET @@session.auto_increment_increment=1, @@session.auto_increment_offset=1/*!*/;
/*!\C utf8mb4 *//*!*/;
SET @@session.character_set_client=45,@@session.collation_connection=45,@@session.collation_server=45/*!*/;
SET @@session.lc_time_names=0/*!*/;
SET @@session.collation_database=DEFAULT/*!*/;
BEGIN
/*!*/;
# at 809
#200712 21:33:44 server id 0  end_log_pos 860 CRC32 0x6aa48d0d 	Table_map: `test`.`int_test` mapped to number 107
# at 860
#200712 21:33:44 server id 0  end_log_pos 900 CRC32 0xb6d5df66 	Write_rows: table id 107 flags: STMT_END_F
### INSERT INTO `test`.`int_test`
### SET
###   @1=8
# at 900
#200712 21:33:44 server id 0  end_log_pos 931 CRC32 0x5b5c9d33 	Xid = 15
COMMIT/*!*/;
# at 931
#200712 21:35:32 server id 0  end_log_pos 954 CRC32 0x95c3815f 	Stop
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;
DELIMITER ;
# End of log file
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```

# 参考

1. [16.1.2.1 Setting the Replication Master Configuration](https://dev.mysql.com/doc/refman/5.7/en/replication-howto-masterbaseconfig.html)
2. [4.6.7.2 mysqlbinlog Row Event Display](https://dev.mysql.com/doc/refman/5.7/en/mysqlbinlog-row-events.html)
