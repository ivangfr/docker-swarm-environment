#!/usr/bin/env bash

docker service create \
--name zookeeper \
--replicas 1 \
--network my-swarm-net \
--publish 2181:2181 \
--env ZOOKEEPER_CLIENT_PORT=2181 \
confluentinc/cp-zookeeper:5.4.1

docker service create \
--name kafka \
--replicas 1 \
--network my-swarm-net \
--publish 29092:29092 \
--env KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
--env KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
--env KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092 \
--env KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
--env KAFKA_DELETE_TOPIC_ENABLE="true" \
confluentinc/cp-kafka:5.4.1

docker service create \
--name elasticsearch \
--replicas 1 \
--network my-swarm-net \
--publish 9200:9200 \
--publish 9300:9300 \
--env cluster.name=docker-es-cluster \
--env discovery.type=single-node \
--env bootstrap.memory_lock="true" \
--env ES_JAVA_OPTS="-Xms512m -Xmx512m" \
docker.elastic.co/elasticsearch/elasticsearch-oss:6.4.2

docker service create \
--name zipkin \
--replicas 1 \
--network my-swarm-net \
--publish 9411:9411 \
openzipkin/zipkin:2.20.2
