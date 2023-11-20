# syntax=docker/dockerfile:1

# 参考资料: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html

FROM ubuntu:22.10

ARG HADOOP_TARBALL=hadoop-3.3.6.tar.gz
# 提前下载好的java8压缩包, 下载地址: https://www.oracle.com/java/technologies/downloads/
ARG JAVA_TARBALL=jdk-8u341-linux-x64.tar.gz

ENV HADOOP_HOME /app/hadoop
ENV JAVA_HOME /usr/java
ENV HBASE_HOME /app/hbase
ENV ZOOKEEPER_HOME /app/zookeeper

# 定义 HBase 版本和下载地址
ARG HBASE_VERSION=2.5.6
ARG HBASE_TARBALL=hbase-${HBASE_VERSION}-bin.tar.gz
ARG HBASE_DOWNLOAD_URL=https://archive.apache.org/dist/hbase/${HBASE_VERSION}/${HBASE_TARBALL}

# 定义 ZooKeeper 版本和下载地址
ARG ZOOKEEPER_VERSION=3.6.3
ARG ZOOKEEPER_TARBALL=apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz
ARG ZOOKEEPER_DOWNLOAD_URL=https://archive.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/${ZOOKEEPER_TARBALL}


RUN sed -i 's/kinetic/focal/g' /etc/apt/sources.list && \
    apt update && \
    apt install -y wget \
    ssh

# 拷贝jdk8安装包
COPY ./${JAVA_TARBALL} ${JAVA_HOME}/${JAVA_TARBALL}
# 拷贝hadoop安装包
COPY ./${HADOOP_TARBALL} ${HADOOP_HOME}/${HADOOP_TARBALL}
# 拷贝hbase安装包
COPY ./${HBASE_TARBALL} ${HBASE_HOME}/${HBASE_TARBALL}
# 拷贝zookeeper安装包
COPY ./${ZOOKEEPER_TARBALL} ${ZOOKEEPER_HOME}/${ZOOKEEPER_TARBALL}


WORKDIR $JAVA_HOME

RUN tar -zxvf /usr/java/${JAVA_TARBALL} --strip-components 1 -C /usr/java && \
    rm /usr/java/${JAVA_TARBALL} && \
    # 设置java8环境变量
    echo export JAVA_HOME=${JAVA_HOME} >> ~/.bashrc && \
    echo export PATH=\$PATH:\$JAVA_HOME/bin >> ~/.bashrc && \
    echo export JAVA_HOME=${JAVA_HOME} >> /etc/profile && \
    echo export PATH=\$PATH:\$JAVA_HOME/bin >> /etc/profile

WORKDIR $HADOOP_HOME

# 下载hadoop安装包
#RUN if [ ! -f "${HADOOP_HOME}/${HBASE_TARBALL}" ]; then \
#    wget --no-check-certificate https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/stable/${HADOOP_TARBALL}

# 解压hadoop安装包
RUN tar -zxvf ${HADOOP_TARBALL} --strip-components 1 -C $HADOOP_HOME && \
    rm ${HADOOP_TARBALL} && \
    # 设置从节点
    echo "worker1\nworker2\nworker3" > $HADOOP_HOME/etc/hadoop/workers && \
    mkdir /app/hdfs && \
    # java8软连接
    ln -s $JAVA_HOME/bin/java /bin/java


# 拷贝hadoop配置文件
COPY ./etc/hadoop/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY ./etc/hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY ./etc/hadoop/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY ./etc/hadoop/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

# 设置hadoop环境变量
RUN echo export JAVA_HOME=$JAVA_HOME >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HADOOP_MAPRED_HOME=$HADOOP_HOME >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HDFS_NAMENODE_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HDFS_DATANODE_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export HDFS_SECONDARYNAMENODE_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export YARN_RESOURCEMANAGER_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo export YARN_NODEMANAGER_USER=root >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh


WORKDIR $HBASE_HOME
# 设置 HBase 环境变量
RUN echo export HBASE_HOME=$HBASE_HOME >> ~/.bashrc && \
    echo export PATH=\$PATH:\$HBASE_HOME/bin >> ~/.bashrc && \
    echo export HBASE_HOME=$HBASE_HOME >> /etc/profile && \
    echo export PATH=\$PATH:\$HBASE_HOME/bin >> /etc/profile
# 下载 HBase 安装包
#RUN if [ ! -f "${HBASE_HOME}/${HBASE_TARBALL}" ]; then \
#    wget --no-check-certificate ${HBASE_DOWNLOAD_URL}

# 解压 HBase 安装包
RUN tar -zxvf ${HBASE_HOME}/${HBASE_TARBALL} --strip-components=1 -C $HBASE_HOME && \
    rm ${HBASE_TARBALL}

# 拷贝 HBase 配置文件
COPY ./etc/hbase/hbase-site.xml $HBASE_HOME/conf/hbase-site.xml
COPY ./etc/hbase/regionservers $HBASE_HOME/conf/regionservers
COPY ./etc/hbase/backup-masters $HBASE_HOME/conf/backup-masters
RUN echo export JAVA_HOME=$JAVA_HOME >> $HBASE_HOME/conf/hbase-env.sh && \
    echo export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP=true >> $HBASE_HOME/conf/hbase-env.sh && \
    echo export HBASE_MANAGES_ZK=false >> $HBASE_HOME/conf/hbase-env.sh

WORKDIR $ZOOKEEPER_HOME

# 安装 zookeeper
RUN tar -zxvf ${ZOOKEEPER_HOME}/${ZOOKEEPER_TARBALL} --strip-components=1 -C ${ZOOKEEPER_HOME} && \
    rm ${ZOOKEEPER_HOME}/${ZOOKEEPER_TARBALL} && \
    echo export ZOOKEEPER_HOME=${ZOOKEEPER_HOME} >> ~/.bashrc && \
    echo export PATH=\$PATH:\${ZOOKEEPER_HOME}/bin >> ~/.bashrc

# 拷贝 zk 配置文件
COPY ./etc/zookeeper/zoo.cfg ${ZOOKEEPER_HOME}/conf/zoo.cfg

# 创建zookeeper数据目录
RUN mkdir -p /app/zookeeper/data && \
    mkdir -p /app/zookeeper/logs && \
    mkdir -p /app/zookeeper/conf && \
    mkdir -p /app/zookeeper/datalog && \
    mkdir -p /app/zookeeper/logs


# 定义 Hive 版本和下载地址
ARG HIVE_VERSION=3.1.2
ARG HIVE_TARBALL=apache-hive-${HIVE_VERSION}-bin.tar.gz
ARG HIVE_DOWNLOAD_URL=https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/${HIVE_TARBALL}

ENV HIVE_HOME /app/hive

# 安装 Hive
WORKDIR /app
#RUN wget --no-check-certificate ${HIVE_DOWNLOAD_URL}
COPY ./$HIVE_TARBALL /app/$HIVE_TARBALL

RUN tar -zxvf ${HIVE_TARBALL} -C /app && \
    mv /app/apache-hive-${HIVE_VERSION}-bin /app/hive && \
    rm ${HIVE_TARBALL}

# 配置 Hive
COPY ./etc/hive/hive-site.xml $HIVE_HOME/conf/hive-site.xml

# 初始化 Hive Metastore（如果使用 Derby）
#RUN $HIVE_HOME/bin/schematool -initSchema -dbType derby

# 设置 Hive 环境变量
RUN echo export HIVE_HOME=$HIVE_HOME >> ~/.bashrc && \
    echo export PATH=\$PATH:\$HIVE_HOME/bin >> ~/.bashrc

# 暴露 Hive Server2 端口（如果需要）
EXPOSE 10000

# ssh免登录设置
RUN echo "/etc/init.d/ssh start" >> ~/.bashrc && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# NameNode WEB UI服务端口
EXPOSE 9870
# nn文件服务端口
EXPOSE 9000
# dfs.namenode.secondary.http-address
EXPOSE 9868
# dfs.datanode.http.address
EXPOSE 9864
# dfs.datanode.address
EXPOSE 9866


# 暴露 HBase 所需的端口
# Master API port
EXPOSE 16000
# Master Web UI
EXPOSE 16010
# RegionServer API port
EXPOSE 16020
# RegionServer Web UI
EXPOSE 16030

# ZooKeeper port
EXPOSE 2181

COPY ./scripts/all_in_one.sh /app
WORKDIR /app

