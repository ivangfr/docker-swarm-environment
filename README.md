# docker-swarm-environment

The goal of this project is to have some examples deployed and running in a cluster of Docker Engines in [`swarm mode`](https://docs.docker.com/engine/swarm/swarm-tutorial)

## Examples

- ### [news-pipeline](https://github.com/ivangfr/docker-swarm-environment/tree/master/news-pipeline#docker-swarm-environment)
- ### [simple-service-keycloak-ldap](https://github.com/ivangfr/docker-swarm-environment/tree/master/simple-service-keycloak-ldap#docker-swarm-environment)

## Prerequisite

- [`Docker`](https://www.docker.com/)
- [`docker-machine`](https://docs.docker.com/machine/overview/)

## Initializing a cluster of docker engines in swarm mode

In the following example, two docker machines will be created. One will act as the **Manager (Leader)** and the another will be the **Worker**. The manager machine will be called `manager1` and the worker machine, `worker1`. Those docker machines that will act as nodes in our Docker Swarm.

The setup of the cluster can be done automatically or manually. All the commands below must be executed in a terminal.

### Automatically

- Open a terminal and navigate to `docker-swarm-environment` root folder

- Run the following script
  ```
  ./setup-docker-swarm.sh
  ```

### Manually

Open a terminal and follow the steps below

- **Create Docker Machines**

  - Run the command to create `manager1` Docker Machine
    ```
    docker-machine create --driver virtualbox --virtualbox-memory 8192 manager1
    ```

  - Run the command to create `worker1` Docker Machine
    ```
    docker-machine create --driver virtualbox --virtualbox-memory 8192 worker1
    ```

  - Check the status of all the Docker machines
    ```
    docker-machine ls
    ```
  
    You should see something similar to
    ```
    NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER     ERRORS
    manager1   -        virtualbox   Running   tcp://192.168.99.108:2376           v19.03.5
    worker1    -        virtualbox   Running   tcp://192.168.99.109:2376           v19.03.5
    ```

- **Initialize a swarm**

  - Export to `MANAGER1_IP` environment variable the ip address of the docker machine `manager1`
    ```
    export MANAGER1_IP=$(docker-machine ip manager1)
    ```

  - Create a new swarm
    ```
    docker-machine ssh manager1 docker swarm init --advertise-addr $MANAGER1_IP
    ```

  - Get the `join-token` for manager and worker. In case you want another node to join as a worker or as a manager, you must use those tokens
    ```
    export MANAGER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet manager)
    export WORKER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet worker)
    ```

  - Join to swarm `worker1` as worker node.
    ```
    docker-machine ssh worker1 docker swarm join --token $WORKER_TOKEN $MANAGER1_IP:2377
    ```

- **Create an overlay network**
  ```
  docker-machine ssh manager1 docker network create --driver overlay --attachable my-swarm-net
  ```

## View swarm members & info

- In a terminal, to view information about Swarm nodes run
  ```
  docker-machine ssh manager1 docker node ls
  ```

  It will prompt something like
  ```
  ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
  n9hpc1g72uof84zl4c50k29uj *   manager1            Ready               Active              Leader              19.03.5
  s26fcddx9mvlzxxxjp3ajqfbo     worker1             Ready               Active                                  19.03.5
  ```

- To see the current state and more information of the Swarm, run
  ```
  docker-machine ssh manager1 docker info
  ```

  The output will be similar to
  ```
  Client:
   Debug Mode: false
  
  Server:
   Containers: 0
    Running: 0
    Paused: 0
    Stopped: 0
   Images: 0
   Server Version: 19.03.5
   Storage Driver: overlay2
    Backing Filesystem: extfs
    Supports d_type: true
    Native Overlay Diff: true
   Logging Driver: json-file
   Cgroup Driver: cgroupfs
   Plugins:
    Volume: local
    Network: bridge host ipvlan macvlan null overlay
    Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
   Swarm: active
    NodeID: n9hpc1g72uof84zl4c50k29uj
    Is Manager: true
    ClusterID: yfd1byp5u7brdq6auyw3ffoym
    Managers: 1
    Nodes: 2
    Default Address Pool: 10.0.0.0/8  
    SubnetSize: 24
    Data Path Port: 4789
    Orchestration:
     Task History Retention Limit: 5
    Raft:
     Snapshot Interval: 10000
     Number of Old Snapshots to Retain: 0
     Heartbeat Tick: 1
     Election Tick: 10
    Dispatcher:
     Heartbeat Period: 5 seconds
    CA Configuration:
     Expiry Duration: 3 months
     Force Rotate: 0
    Autolock Managers: false
    Root Rotation In Progress: false
    Node Address: 192.168.99.108
    Manager Addresses:
     192.168.99.108:2377
   Runtimes: runc
   Default Runtime: runc
   Init Binary: docker-init
   containerd version: b34a5c8af56e510852c35414db4c1f4fa6172339
   runc version: 3e425f80a8c931f88e6d94a8c831b9d5aa481657
   init version: fec3683
   Security Options:
    seccomp
     Profile: default
   Kernel Version: 4.14.154-boot2docker
   Operating System: Boot2Docker 19.03.5 (TCL 10.1)
   OSType: linux
   Architecture: x86_64
   CPUs: 1
   Total Memory: 989.5MiB
   Name: manager1
   ID: BFTO:X4FP:ZGWJ:WKDO:SA5T:MZAW:NLYP:D3YY:WCTP:7ZZU:NLR4:2HQU
   Docker Root Dir: /mnt/sda1/var/lib/docker
   Debug Mode: false
   Registry: https://index.docker.io/v1/
   Labels:
    provider=virtualbox
   Experimental: false
   Insecure Registries:
    127.0.0.0/8
   Live Restore Enabled: false
   Product License: Community Engine
  ```

## Cleaning up  

In a terminal, run the command below o remove `manager1` and `worker1` docker machines
```
docker-machine rm worker1 manager1
```
