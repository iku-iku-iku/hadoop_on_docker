# hadoop on docker

基于docker的hadoop集群

## 1. 配置

需要先下载一些东西，下载链接在dockerfile中，但是为了避免重复下载，没有在build镜像的时候下载，需要手动下载

- apache-hive-3.1.2-bin.tar.gz
- apache-zookeeper-3.6.3-bin.tar.gz
- hadoop-3.3.6.tar.gz
- hbase-2.5.6-bin.tar.gz
- jdk-8u341-linux-x64.tar.gz

## 2. 运行

```shell
# build image
docker build -t hadoop .
# start cluster
docker-compose up -d
# stop cluster
docker-compose down
```

## 3. 启动集群

scripts/all_in_one.sh 会被拷贝到image中，可以执行如下命令启动集群

```shell
chmod a+x ./all_in_one.sh
./all_in_one.sh start_all
```

该脚本可以扩充，尽量把集群的操作写在脚本里面
