---
layout: post
title:  "数据惊魂日"
date:   2019-05-05 10:59:06
categories: mysql data recovery innodb
---

### 事件起因
  早起删除mysql库中异常数据，使用控制台ssh连接上进行删除。第一次删除成功，第二次删除改写where条件。中文输入法忘记关闭，没有确认SQL语句，点击Enter..........意外的整表被清空了。
  
  第一件事锁表 `lock table xxx;`
  
  开搜索引擎开始查找，大多方案都是通过binlog进行恢复。但是我的mysql跑在了arm的机器上，为了节省资源没开binlog.

  继续搜索找到了一个通过ibd文件 恢复的方案。首先备份你的idb文件。

### 下载并编译恢复程序
```sh
#下载并解压文件
wget https://launchpad.net/percona-data-recovery-tool-for-innodb/trunk/release-0.5/+download/percona-data-recovery-tool-for-innodb-0.5.tar.gz
tar -zxvf percona-data-recovery-tool-for-innodb-0.5.tar.gz
#准备编译环境，在arm的机器上好多类库不好找到，我已经把idb文件拷贝到另外 一台x86的centos机器上
#安装依赖库
yum install  ncurses-devel libc-dev glibc-devel
cd percona-data-recovery-tool-for-innodb-0.5/mysql-sorce
./configure
cd ..
make -j4
#请检查编译结果，可能会有警告，只要没有错误就行。

#准备开始恢复数据
./page_parser -5 -f ~/mysql/temp_monitor.ibd 
#之后会产生一个pages-888888888的目录
#通过线上的表结构创建.h文件 
mysql/percona-data-recovery-tool-for-innodb-0.5/create_defs.pl --host localhost --user xxxx  --db YYYYY --table zzzzz >include/table_defs.h
#再次执行make
make
#恢复数据文件 ,同时 程序会帮你产生一个恢复脚本 
./constraints_parser -D -5 -f pages-1557083133/FIL_PAGE_INDEX/0-21/ > /tmp/temp_monitor.dbf
LOAD DATA INFILE '/root/mysql/percona-data-recovery-tool-for-innodb-0.5/dumps/default/temp_monitor' REPLACE INTO TABLE `temp_monitor` FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '"' LINES STARTING BY 'temp_monitor\t' (id, ambient_temperature, cpu_temperature, humidity, date);

#之后将以上文件 拷贝回生产机器，连入数据库执行以上命令即可恢复数据
```

### 经验终结

1. 在一些条件不太好情况下需要通过控制台直接操作数据库的，请先dump下吧。
2. 如果机器性能允许请打开bilog
3. 一旦有误操作，请先锁表。
4. 需要直接操作时的机器尽量不装中文输入法。
4. $\color{red}{小心小心再小心}$