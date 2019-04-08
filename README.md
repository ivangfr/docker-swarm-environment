# `docker-swarm-environment`

The goal of this project is to have some examples using [`Docker Swarm`](https://docs.docker.com/engine/swarm/swarm-tutorial)

## Examples

### [keycloak-clustered-mode](https://github.com/ivangfr/docker-swarm-environment/tree/master/keycloak-clustered-mode)

The goal of this project is to deploy [`keycloak-clustered`](https://github.com/ivangfr/keycloak-clustered) instances
in `Docker Swarm`.

### More soon

## Initializing a cluster of docker engines in swarm mode

In this example, two docker machines will be created. One will act as the **Manager (Leader)** and the another will be
the **Worker**. The manager machine will be called `manager1` and the worker machine, `worker1`.

The setup of the cluster can be done automatically or manually.

### Automatically

- Go to `docker-swarm` folder and run the following script
```
./setup-docker-swarm.sh
```

### Manually

#### Create Docker Machines

- Create a set of Docker machines that will act as nodes in our Docker Swarm.

Below, it's the command to create a Docker Machine named `manager1`.
```
docker-machine create --driver virtualbox manager1
```

Run the same command to create Docker Machine for `worker1`.
```
docker-machine create --driver virtualbox worker1
```

- Check the status of all the Docker machines by running `docker-machine ls`
```
NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
manager1   -        virtualbox   Running   tcp://192.168.99.100:2376           v18.05.0-ce
worker1    -        virtualbox   Running   tcp://192.168.99.101:2376           v18.05.0-ce
```

#### Initialize a swarm

- Export to `MANAGER1_IP` environment variable the ip address of the docker machine `manager1`
```
export MANAGER1_IP=$(docker-machine ip manager1)
```

- Run the following command to create a new swarm
```
docker-machine ssh manager1 docker swarm init --advertise-addr $MANAGER1_IP
```

- Run the commands below to get the join-token for manager and worker. In case you want another node to join as a worker or as a manager, you must use those tokens.
```
export MANAGER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet manager)
export WORKER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet worker)
```

- Run the command below to join to swarm `worker1` as worker node.
```
docker-machine ssh worker1 docker swarm join --token $WORKER_TOKEN $MANAGER1_IP:2377
```

#### Create an overlay network

- Run the command below the create an overlay network for swarm
```
docker-machine ssh manager1 docker network create --driver overlay --attachable my-swarm-net
```

## View swarm members & info

- To view information about Swarm nodes run
```
docker-machine ssh manager1 docker node ls
```

It will prompt something like
```
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
vctbwhaa0w6xfhdg4gz78ppr1 *   manager1            Ready               Active              Leader              18.05.0-ce
x8x3jgbyf974v0wuah9ol95gn     worker1             Ready               Active                                  18.05.0-ce
```

- To see the current state and more information of the Swarm, run
```
docker-machine ssh manager1 docker info
```

The output will be similar to
```
Containers: 0
 Running: 0
 Paused: 0
 Stopped: 0
...
Swarm: active
 NodeID: vctbwhaa0w6xfhdg4gz78ppr1
 Is Manager: true
 ClusterID: w1to6d4p1pfxbqq7up57jew8k
 Managers: 1
 Nodes: 2
...
 Node Address: 192.168.99.100
 Manager Addresses:
  192.168.99.100:2377
  192.168.99.101:2377
...
```

## Cleaning up  

To remove `manager1` and `worker1` docker machines, run
```
docker-machine rm manager1 worker1
```