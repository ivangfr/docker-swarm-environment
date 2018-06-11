# docker-swarm-environment

## Goal

The goal of this project is have some examples using [`Docker Swarm`](https://docs.docker.com/engine/swarm/swarm-tutorial)

### - [`keycloak-clustered-mode`](https://github.com/ivangfr/docker-swarm-environment/tree/master/keycloak-clustered)

The goal of this project is to deploy [`keycloak-clustered`](https://github.com/ivangfr/keycloak-clustered) instances in `Docker Swarm`.

### - More soon

## Initializing a cluster of docker engines in swarm mode

In this example, four docker machines will be created. Two will act as the **Manager (Leader)** and the other two will be **Workers**. The manager machines will be called `manager1` and `manager2`. The worker machines will be called `worker1` and `worker2`.

The setup of the cluster can be done automatically or manually.

### Automatically

- Go to `docker-swarm` folder and run the following script
```
./setup-docker-swarm.sh
```

### Manually

#### Create Docker Machines

- Create a set of Docker machines that will act as nodes in our Docker Swarm.

Bellow, it's the command to create a Docker Machine named `manager1`.
```
docker-machine create --driver virtualbox manager1
```

Run the same command to create Docker Machine for `manager2`, `worker1` and `worker2`.
```
docker-machine create --driver virtualbox manager2
docker-machine create --driver virtualbox worker1
docker-machine create --driver virtualbox worker2
```

- Check the status of all the Docker machines by running `docker-machine ls`
```
NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
manager1   -        virtualbox   Running   tcp://192.168.99.100:2376           v18.05.0-ce
manager2   -        virtualbox   Running   tcp://192.168.99.101:2376           v18.05.0-ce
worker1    -        virtualbox   Running   tcp://192.168.99.102:2376           v18.05.0-ce
worker2    -        virtualbox   Running   tcp://192.168.99.103:2376           v18.05.0-ce
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

- Run the commands bellow to get the join-token for manager and worker. In case you want another node to join as a worker or as a manager, you must use those tokens.
```
export MANAGER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet manager)
export WORKER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet worker)
```

- Run the commands bellow to join to swarm `manager2` as manager node and `worker1` and `worker2` as worker nodes.
```
docker-machine ssh manager2 docker swarm join --token $MANAGER_TOKEN $MANAGER1_IP:2377
docker-machine ssh worker1 docker swarm join --token $WORKER_TOKEN $MANAGER1_IP:2377
docker-machine ssh worker2 docker swarm join --token $WORKER_TOKEN $MANAGER1_IP:2377
```

#### Create an overlay network

- Run the command bellow the create an overlay network for swarm
```
docker-machine ssh manager1 docker network create --driver overlay my-swarm-net
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
kmioetkjzfu9rzx7xv7vsjacf     manager2            Ready               Active              Reachable           18.05.0-ce
x8x3jgbyf974v0wuah9ol95gn     worker1             Ready               Active                                  18.05.0-ce
8iphn80t2dwhnxtm3qy9u1s80     worker2             Ready               Active                                  18.05.0-ce
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
 Managers: 2
 Nodes: 4
...
 Node Address: 192.168.99.100
 Manager Addresses:
  192.168.99.100:2377
  192.168.99.101:2377
...

```