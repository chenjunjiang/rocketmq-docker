#!/bin/bash

# Build base image
docker build -t apache/rocketmq-base:4.3.0 --build-arg version=4.3.0 ./rocketmq-base

# Build namesrv and broker
docker build -t apache/rocketmq-namesrv:4.3.0 ./rocketmq-namesrv
docker build -t apache/rocketmq-broker:4.3.0 ./rocketmq-broker

# Run namesrv and broker

#单机
#docker run -d -p 9876:9876 --name rmqnamesrv -e "JAVA_OPT_EXT=-server -Xms128m -Xmx256m -Xmn128m"  apache/rocketmq-namesrv:4.3.0 
#docker run -d -p 10911:10911 -p 10909:10909 --name rmqbroker --link rmqnamesrv:namesrv -e "NAMESRV_ADDR=namesrv:9876" -e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" apache/rocketmq-broker:4.3.0
#集群
docker run -d -p 9876:9876 --name rmqnamesrv1 -e "JAVA_OPT_EXT=-server -Xms128m -Xmx256m -Xmn128m" -v d:/opt:/opt/ apache/rocketmq-namesrv:4.3.0 
docker run -d -p 9877:9876 --name rmqnamesrv2 -e "JAVA_OPT_EXT=-server -Xms128m -Xmx256m -Xmn128m"  -v d:/opt:/opt/ apache/rocketmq-namesrv:4.3.0 
docker run -d -p 10911:10911 -p 10909:10909 -p 10912:10912 --name rmqbroker-a --link rmqnamesrv1:namesrv1 --link rmqnamesrv2:namesrv2 -e "broker=broker-a" -e "NAMESRV_ADDR=namesrv1:9876;namesrv2:9877" -e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" -v d:/opt:/opt/ apache/rocketmq-broker:4.3.0
docker run -d -p 11911:11911 -p 11909:11909 -p 11912:11912 --name rmqbroker-b --link rmqnamesrv1:namesrv1 --link rmqnamesrv2:namesrv2 -e "broker=broker-b" -e "NAMESRV_ADDR=namesrv1:9876;namesrv2:9877" -e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" -v d:/opt:/opt/ apache/rocketmq-broker:4.3.0
docker run -d -p 11011:11011 -p 11009:11009 -p 11012:11012 --name rmqbroker-a-s --link rmqnamesrv1:namesrv1 --link rmqnamesrv2:namesrv2 -e "broker=broker-a-s" -e "NAMESRV_ADDR=namesrv1:9876;namesrv2:9877" -e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" -v d:/opt:/opt/ apache/rocketmq-broker:4.3.0
docker run -d -p 12011:12011 -p 12009:12009 -p 12012:12012 --name rmqbroker-b-s --link rmqnamesrv1:namesrv1 --link rmqnamesrv2:namesrv2 -e "broker=broker-b-s" -e "NAMESRV_ADDR=namesrv1:9876;namesrv2:9877" -e "JAVA_OPT_EXT=-server -Xms128m -Xmx128m -Xmn128m" -v d:/opt:/opt/ apache/rocketmq-broker:4.3.0
