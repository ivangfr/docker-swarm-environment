# keycloak-clustered-mode

## Goal

The goal of this project is to deploy [`keycloak-clustered`](https://github.com/ivangfr/keycloak-clustered) instances into [`Docker Swarm`](https://docs.docker.com/engine/swarm/swarm-tutorial).

## Deploy services to swarm

Once a cluster of docker engines in swarm mode is initialized, we can start deployng services.

#### Use _manager1_ Docker Daemon
```
eval $(docker-machine env manager1)
```
> when `manager1` host won't be used anymore, you can undo this change by running
> ```
> eval $(docker-machine env -u)
> ```

#### Create [MySQL](https://hub.docker.com/_/mysql) service

```
docker service create \
--name keycloak-mysql \
--replicas 1 \
--network my-swarm-net \
--publish 3306:3306 \
--env MYSQL_DATABASE=keycloak \
--env MYSQL_USER=keycloak \
--env MYSQL_PASSWORD=password \
--env MYSQL_ROOT_PASSWORD=root_password \
mysql:5.7.22
```
> To remove `keycloak-database` service run
> ```
> docker service rm keycloak-database
> ```

#### Create Keycloak service

***Note. Cluster hosts are not joined together! [More about](https://www.keycloak.org/docs/latest/server_installation/index.html#troubleshooting-2)***

```
docker service create \
--name keycloak \
--replicas 2 \
--network my-swarm-net \
--publish 8080:8080 \
--env KEYCLOAK_USER=admin \
--env KEYCLOAK_PASSWORD=admin \
--env DIST_CACHE_OWNERS=2 \
ivanfranchin/keycloak-clustered:latest
```
> To remove keycloak service run
> ```
> docker service rm keycloak
> ```

#### To see the status of the service run
```
docker service ls
```

#### To check how it is getting orchestrated to the different nodes run
```
docker service ps keycloak-mysql
docker service ps keycloak
```