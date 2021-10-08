#!/usr/bin/env bash

docker service create \
--name eureka \
--replicas 1 \
--publish 8761:8761 \
--network my-swarm-net \
ivanfranchin/eureka-server:1.0.0

docker service create \
--name producer-api \
--replicas 1 \
--publish 9080:8080 \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env SCHEMA_REGISTRY_HOST=schema-registry \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/producer-api:1.0.0

docker service create \
--name categorizer-service \
--replicas 1 \
--publish 9081:8080 \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env SCHEMA_REGISTRY_HOST=schema-registry \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/categorizer-service:1.0.0

docker service create \
--name collector-service \
--replicas 1 \
--publish 9082:8080 \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env SCHEMA_REGISTRY_HOST=schema-registry \
--env ELASTICSEARCH_HOST=elasticsearch \
--env EUREKA_HOST=eureka -e ZIPKIN_HOST=zipkin \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/collector-service:1.0.0

docker service create \
--name publisher-api \
--replicas 1 \
--publish 9083:8080 \
--env ELASTICSEARCH_HOST=elasticsearch \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/publisher-api:1.0.0

docker service create \
--name news-client \
--replicas 1 \
--publish 8080:8080 \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env SCHEMA_REGISTRY_HOST=schema-registry \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/news-client:1.0.0
