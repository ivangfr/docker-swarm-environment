# keycloak-clustered-mode

## Goal

The goal of this project is to deploy [`keycloak-clustered`](https://github.com/ivangfr/keycloak-clustered) instances into [`Docker Swarm`](https://docs.docker.com/engine/swarm/swarm-tutorial).

## Deploy services to swarm

Once a cluster of docker machines in swarm mode is initialized, we can start deploying services.

#### 1. Use _manager1_ Docker Daemon
```
eval $(docker-machine env manager1)
```
> when `manager1` host won't be used anymore, you can undo this change by running
> ```
> eval $(docker-machine env -u)
> ```

#### 2. Create [MySQL](https://hub.docker.com/_/mysql) service

```
docker service create \
--name mysql \
--replicas 1 \
--network my-swarm-net \
--publish 3306:3306 \
--env MYSQL_DATABASE=keycloak \
--env MYSQL_USER=keycloak \
--env MYSQL_PASSWORD=password \
--env MYSQL_ROOT_PASSWORD=root_password \
mysql:5.7.22
```
> To remove `mysql` service run
> ```
> docker service rm mysql
> ```

#### 3. Startup Keycloak-Clustered Database

- Create `keycloak-startup` service. It has just one replica and will startup the database, add `admin` user and create the `JGROUPSPING` table, that is used by `JDBC_PING` protocol to discover `keycloak-clustered` instances in the cluster. 
```
docker service create \
--name keycloak-startup \
--replicas 1 \
--network my-swarm-net \
--publish 8080:8080 \
--env KEYCLOAK_USER=admin \
--env KEYCLOAK_PASSWORD=admin \
--env DIST_CACHE_OWNERS=2 \
--env JDBC_PARAMS=useSSL=false \
ivanfranchin/keycloak-clustered:4.0.0.Final
```
> **Some errors can occur in this step. See [`Troubleshooting`](#Troubleshooting) section for help.**

- To see the logs of `keycloak-startup` service creation, run
```
docker service logs keycloak-startup -f
```

- Once `keycloak-startup` service is up and running, remove it
```
docker service rm keycloak-startup
```

#### 4. Create `keycloak-clustered` service

- Run the following command to start `keycloak-clustered` service with one replica.
```
docker service create \
--name keycloak-clustered \
--replicas 1 \
--network my-swarm-net \
--publish 8080:8080 \
--env DIST_CACHE_OWNERS=2 \
--env JDBC_PARAMS=useSSL=false \
ivanfranchin/keycloak-clustered:4.0.0.Final
```
> **Some errors can occur in this step. See [`Troubleshooting`](#Troubleshooting) section for help.**
>
> To remove `keycloak-clustered` service run
> ```
> docker service rm keycloak-clustered
> ```

- Running the following command, you scale `keycloak-clustered` service to 3 replicas
```
docker service scale keycloak-clustered=3
```
> **Some errors can occur in this step. See [`Troubleshooting`](#Troubleshooting) section for help.**

#### 5. See the status of the services
```
docker service ls
```
You should see something similar to
```
ID            NAME                MODE        REPLICAS  IMAGE                                        PORTS
7u1r1kcd1wne  keycloak-clustered  replicated  3/3       ivanfranchin/keycloak-clustered:4.0.0.Final  *:8080->8080/tcp
i4qh1whw9kj1  mysql               replicated  1/1       mysql:5.7.22                                 *:3306->3306/tcp
```

#### 6. Check how the services are getting orchestrated to the different nodes

- To see about `mysql` service, run
```
docker service ps mysql
```
You should see something like
```
ID            NAME     IMAGE         NODE      DESIRED STATE  CURRENT STATE           ERROR  PORTS
tu5sqfwfwefe  mysql.1  mysql:5.7.22  manager1  Running        Running 18 minutes ago
```

- Running the command bellow shows how `keycloak-clustered` replicas are distributed over the docker swarm machines
```
docker service ps keycloak-clustered
```
You should see something similar to
```
ID            NAME                  IMAGE                                        NODE      DESIRED STATE  CURRENT STATE           ERROR  PORTS
pxbw91r3wacu  keycloak-clustered.1  ivanfranchin/keycloak-clustered:4.0.0.Final  worker1   Running        Running 53 seconds ago
fjpki4b36n5e  keycloak-clustered.2  ivanfranchin/keycloak-clustered:4.0.0.Final  worker1   Running        Running 26 seconds ago
x20ey8uyryqa  keycloak-clustered.3  ivanfranchin/keycloak-clustered:4.0.0.Final  manager1  Running        Running 11 seconds ago
```
In the case above, one replica is running in `manager1` and two in `worker1`

#### 7. Check records in `JGROUPSPING` table

- Run `docker exec` on the `mysql` running container

- Inside the container, log in `mysql`
```
mysql -ukeycloak -ppassword
```

- Inside `MySQL` run the following `select`
```
select * from keycloak.JGROUPSPING;
```

## Troubleshooting

Sometimes, an exception like the one shown bellow is thrown while creating `keycloak-startup` or `keycloak-clustered` service, or scaling the last
```
ERROR [org.hibernate.engine.jdbc.spi.SqlExceptionHelper] (ServerService Thread Pool -- 56)
javax.resource.ResourceException: IJ000470: You are trying to use a connection factory that has been shut down:
java:jboss/datasources/KeycloakDS
```
It happens usually when, during service creation, there are more than one replica starting up at the same time. In this case, it is recommended to create the service with just one replica and then, scale it. If there is just one replica starting up and, even so, the error occurs, it is expected the single replica will start up successfully after its first restart.