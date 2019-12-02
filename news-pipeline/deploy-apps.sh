#!/usr/bin/env bash

docker service create \
--name eureka \
--replicas 1 \
--publish 8761:8761 \
--network my-swarm-net \
docker.mycompany.com/eureka-server:1.0.0

docker service create \
--name producer-api \
--replicas 1 \
--publish 9080:8080 \
--network my-swarm-net \
--restart-condition="on-failure" \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
docker.mycompany.com/producer-api:1.0.0

docker service create \
--name categorizer-service \
--replicas 1 \
--publish 9081:8080 \
--network my-swarm-net \
--restart-condition="on-failure" \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
docker.mycompany.com/categorizer-service:1.0.0

docker service create \
--name collector-service \
--replicas 1 \
--publish 9082:8080 \
--network my-swarm-net \
--restart-condition="on-failure" \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env ELASTICSEARCH_HOST=elasticsearch \
--env EUREKA_HOST=eureka -e ZIPKIN_HOST=zipkin \
docker.mycompany.com/collector-service:1.0.0

docker service create \
--name publisher-api \
--replicas 1 \
--publish 9083:8080 \
--network my-swarm-net \
--restart-condition="on-failure" \
--env ELASTICSEARCH_HOST=elasticsearch \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
docker.mycompany.com/publisher-api:1.0.0

docker service create \
--name news-client \
--replicas 1 \
--publish 8080:8080 \
--network my-swarm-net \
--restart-condition="on-failure" \
--env KAFKA_HOST=kafka \
--env KAFKA_PORT=9092 \
--env EUREKA_HOST=eureka \
--env ZIPKIN_HOST=zipkin \
docker.mycompany.com/news-client:1.0.0
