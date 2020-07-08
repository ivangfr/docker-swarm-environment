#!/usr/bin/env bash

docker service create \
--name simple-service \
--replicas 1 \
--network my-swarm-net \
--restart-condition="on-failure" \
--publish 9080:8080 \
--env KEYCLOAK_HOST=keycloak \
docker.mycompany.com/simple-service:1.0.0
