#!/usr/bin/env bash

docker service create \
--name zookeeper \
--replicas 1 \
--publish 2181:2181 \
--env ZOOKEEPER_CLIENT_PORT=2181 \
--restart-condition="on-failure" \
--network my-swarm-net \
confluentinc/cp-zookeeper:6.1.1

docker service create \
--name kafka \
--replicas 1 \
--publish 29092:29092 \
--env KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
--env KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT \
--env KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092 \
--env KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
--env KAFKA_DELETE_TOPIC_ENABLE="true" \
--restart-condition="on-failure" \
--network my-swarm-net \
confluentinc/cp-kafka:6.1.1

docker service create \
--name schema-registry \
--replicas 1 \
--publish 8081:8081 \
--env SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS=kafka:9092 \
--env SCHEMA_REGISTRY_HOST_NAME=schema-registry \
--env SCHEMA_REGISTRY_LISTENERS=http://0.0.0.0:8081 \
--restart-condition="on-failure" \
--network my-swarm-net \
confluentinc/cp-schema-registry:6.1.1

docker service create \
--name elasticsearch \
--replicas 1 \
--publish 9200:9200 \
--publish 9300:9300 \
--env cluster.name=docker-es-cluster \
--env discovery.type=single-node \
--env bootstrap.memory_lock="true" \
--env ES_JAVA_OPTS="-Xms512m -Xmx512m" \
--restart-condition="on-failure" \
--network my-swarm-net \
docker.elastic.co/elasticsearch/elasticsearch:7.12.1

docker service create \
--name zipkin \
--replicas 1 \
--publish 9411:9411 \
--restart-condition="on-failure" \
--network my-swarm-net \
openzipkin/zipkin:2.21.5
