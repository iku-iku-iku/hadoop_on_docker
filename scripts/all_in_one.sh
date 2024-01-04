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
      ssh 192.168.1.$id "echo $id > $ZK_HOME/data/myid" 
      ssh 192.168.1.$id "$ZK_HOME/bin/zkServer.sh start"
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
