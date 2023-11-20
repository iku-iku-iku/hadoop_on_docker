#!/bin/bash

HADOOP_HOME=/app/hadoop
HBASE_HOME=/app/hbase
ZK_HOME=/app/zookeeper

case "$1" in
  "start_all") 
    $HADOOP_HOME/bin/hdfs namenode -format
    $HADOOP_HOME/sbin/start-all.sh
    for id in 1 2 3
    do
      ssh worker$id $ZK_HOME/bin/zkServer.sh start
      ssh worker$id echo $id > $ZK_HOME/data/myid
    done
    $HBASE_HOME/bin/start-hbase.sh
  ;;
  "hbase_shell")
    $HBASE_HOME/bin/hbase shell
  ;;
  "stop_all")
    $HADOOP_HOME/sbin/stop-all.sh
  ;;
  *) echo default
  ;;
esac
