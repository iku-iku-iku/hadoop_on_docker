# hadoop on docker

基于docker的hadoop集群

## 1. 配置

首先要根据这篇文章配置一下hadoop集群。[基于Docker搭建hadoop完全分布式集群](https://zhuanlan.zhihu.com/p/563579715)

> 在`etc`目录下，添加hadoop的四个配置文件`core-site.xml, hdfs-site.xml, mapred-site.xml, yarn-site.xml`就好了

需要先下载一些东西，下载链接在dockerfile中，但是为了避免重复下载，没有在build镜像的时候下载，需要手动下载

- apache-hive-3.1.2-bin.tar.gz
- apache-zookeeper-3.6.3-bin.tar.gz
- hadoop-3.3.6.tar.gz
- hbase-2.5.6-bin.tar.gz
- jdk-8u341-linux-x64.tar.gz

## 2. 运行

```shell
# build image
make build
# start cluster
make cluster
# stop cluster
make stop
# run bash on master
make run
```

don't use `make run` directly, check your docker container name, and then fix the command in Makefile

> like: my docker container name is `hadoop_on_docker-master1_1`, so I need change the command into `docker exec -it hadoop_on_docker_master1_1 bash`

## 3. 启动集群

scripts/all_in_one.sh 会被拷贝到image中，可以执行如下命令启动集群

```shell
chmod a+x ./all_in_one.sh
./all_in_one.sh start_all
```

该脚本可以扩充，尽量把集群的操作写在脚本里面

## 4 项目组件的使用

大部分组件都在对应目录的`bin`目录下，比如使用hadoop的`hdfs`功能，`cd /app/hadoop/bin && ./hdfs`即可

## 5 hive的使用

目前并没有配置`mysql`数据库，所以hive使用的是内置的`derby`数据库，如果是想用`mysql`，那就需要你自己配置了。

### 现在有个未知的bug，复现如下：

```
# 启动hive / start hive CLI

root@hadoop330:/app/hive/bin# ./hive
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/app/hive/lib/log4j-slf4j-impl-2.10.0.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/app/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.apache.logging.slf4j.Log4jLoggerFactory]
Hive Session ID = 4c35f7c3-3b15-4005-b2ca-a261d03d6b2c

Logging initialized using configuration in jar:file:/app/hive/lib/hive-common-3.1.2.jar!/hive-log4j2.properties Async: true
Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions. Consider using a different execution engine (i.e. spark, tez) or using Hive 1.X releases.

hive>
    >
    > show databases;
FAILED: HiveException java.lang.RuntimeException: Unable to instantiate org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient

```

解决办法/ solution :
重新创建一个默认DB，**这种操作会导致原有数据库丢失，请谨慎操作**

```
root@hadoop330:/app/hive/bin#
root@hadoop330:/app/hive/bin# ls
beeline  derby.log  ext  hive  hive-config.sh  hiveserver2  hplsql  init-hive-dfs.sh  metastore_db  metatool  schematool
root@hadoop330:/app/hive/bin# rm -rf metastore_db
root@hadoop330:/app/hive/bin# ls
beeline  derby.log  ext  hive  hive-config.sh  hiveserver2  hplsql  init-hive-dfs.sh  metatool  schematool
root@hadoop330:/app/hive/bin#
root@hadoop330:/app/hive/bin# ./schematool -initSchema -dbType derby

...
Initialization script completed
schemaTool completed

root@hadoop330:/app/hive/bin# ls
beeline  derby.log  ext  hive  hive-config.sh  hiveserver2  hplsql  init-hive-dfs.sh  metastore_db  metatool  schematool
```

> 也许能够使用`beeline`来连接，但是我没试过。