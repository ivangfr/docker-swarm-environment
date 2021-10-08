#!/usr/bin/env bash

docker service create \
--name simple-service \
--replicas 1 \
--publish 9080:8080 \
--env KEYCLOAK_HOST=keycloak \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/simple-service:1.0.0
