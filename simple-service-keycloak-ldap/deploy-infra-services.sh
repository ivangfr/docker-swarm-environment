#!/usr/bin/env bash

docker service create \
--name openldap \
--replicas 1 \
--publish 389:389 \
--env LDAP_ORGANISATION="MyCompany Inc." \
--env LDAP_DOMAIN=mycompany.com \
--restart-condition="on-failure" \
--network my-swarm-net \
osixia/openldap:1.5.0

docker service create \
--name phpldapadmin \
--replicas 1 \
--publish 6443:443 \
--env PHPLDAPADMIN_LDAP_HOSTS=openldap \
--restart-condition="on-failure" \
--network my-swarm-net \
osixia/phpldapadmin:0.9.0

docker service create \
--name mysql \
--replicas 1 \
--publish 3306:3306 \
--env MYSQL_DATABASE=keycloak \
--env MYSQL_USER=keycloak \
--env MYSQL_PASSWORD=password \
--env MYSQL_ROOT_PASSWORD=root_password \
--restart-condition="on-failure" \
--network my-swarm-net \
mysql:5.7.35

docker service create \
--name keycloak \
--replicas 2 \
--publish 8080:8080 \
--env KEYCLOAK_USER=admin \
--env KEYCLOAK_PASSWORD=admin \
--env DB_VENDOR=mysql \
--env DB_ADDR=mysql \
--env DB_USER=keycloak \
--env DB_PASSWORD=password \
--env JDBC_PARAMS=useSSL=false \
--env JGROUPS_DISCOVERY_PROTOCOL=JDBC_PING \
--env JGROUPS_DISCOVERY_PROPERTIES=datasource_jndi_name=java:jboss/datasources/KeycloakDS \
--restart-condition="on-failure" \
--network my-swarm-net \
ivanfranchin/keycloak-clustered:latest
