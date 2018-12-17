#!/bin/bash

export ROCKETMQ_VERSION=4.3.0
export ROCKETMQ_HOME=/opt/rocketmq-${ROCKETMQ_VERSION}

# Build base image,这里的version不能通过${ROCKETMQ_VERSION}的方式引用
docker build -t apache/rocketmq-base:4.3.0 --build-arg version=4.3.0 ./rocketmq-base

# Build namesrv and broker image
docker build -t apache/rocketmq-namesrv:4.3.0 ./rocketmq-namesrv
docker build -t apache/rocketmq-broker:4.3.0 ./rocketmq-broker

# Run namesrv and broker
docker-compose -f docker-compose/docker-compose-aggregate.yml up -d
