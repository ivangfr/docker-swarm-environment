# docker-swarm-environment

The goal of this project is to have some examples deployed and running in a cluster of Docker Engines in [`swarm mode`](https://docs.docker.com/engine/swarm/swarm-tutorial)

## Examples

- ### [news-pipeline](https://github.com/ivangfr/docker-swarm-environment/tree/master/news-pipeline#docker-swarm-environment)
- ### [simple-service-keycloak-ldap](https://github.com/ivangfr/docker-swarm-environment/tree/master/simple-service-keycloak-ldap#docker-swarm-environment)

## Prerequisite

- [`Docker`](https://www.docker.com/)
- [`docker-machine`](https://docs.docker.com/machine/overview/)

## Initializing a cluster of Docker Engines in swarm mode

In the following example, two Docker machines will be created. One will act as the **Manager (Leader)** and the another will be the **Worker**. The manager machine will be called `manager1` and the worker machine, `worker1`. Those docker machines will act as nodes in our Docker Swarm.

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
  60hh6m3rqqch60u7yza9lf6f5 *   manager1            Ready               Active              Leader              19.03.12
  21urc24cgvwq6vjwuizy1bnar     worker1             Ready               Active                                  19.03.12
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
   Server Version: 19.03.12
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
    NodeID: 60hh6m3rqqch60u7yza9lf6f5
    Is Manager: true
    ClusterID: ocflb0g33nrvh79n85lob6lhc
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
    Node Address: 192.168.99.120
    Manager Addresses:
     192.168.99.120:2377
   Runtimes: runc
   Default Runtime: runc
   Init Binary: docker-init
   containerd version: 7ad184331fa3e55e52b890ea95e65ba581ae3429
   runc version: dc9208a3303feef5b3839f4323d9beb36df0a9dd
   init version: fec3683
   Security Options:
    seccomp
     Profile: default
   Kernel Version: 4.19.130-boot2docker
   Operating System: Boot2Docker 19.03.12 (TCL 10.1)
   OSType: linux
   Architecture: x86_64
   CPUs: 1
   Total Memory: 7.79GiB
   Name: manager1
   ID: XAYV:H4TN:VI2S:D22T:PISE:G6QA:WMXJ:YKYB:QRBV:7ZXB:IRB3:XEM5
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

## Issues

Unable to upgrade this project because, while running `setup-docker-swarm.sh` script, I am getting the following error while creating `manager1` and `worker1`
```
Error creating machine: Error checking the host: Error checking and/or regenerating the certs: There was an error validating certificates for host "192.168.99.132:2376": dial tcp 192.168.99.132:2376: i/o timeout
```

Besides, after the script finishes, I cannot access docker-daemon from `manager1` and `worker1` machines
```
$ eval $(docker-machine env manager1)
Error checking TLS connection: Error checking and/or regenerating the certs: There was an error validating certificates for host "192.168.99.131:2376": dial tcp 192.168.99.131:2376: i/o timeout
You can attempt to regenerate them using 'docker-machine regenerate-certs [name]'.
Be advised that this will trigger a Docker daemon restart which might stop running containers.
```
