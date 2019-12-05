# `docker-swarm-environment`
## `> news-pipeline`

In this example, we are going to deploy, into a cluster of Docker Engines in swarm mode, the applications present in the repository [`spring-cloud-stream-elasticsearch`](https://github.com/ivangfr/spring-cloud-stream-elasticsearch)

So, let's start the Docker Engines cluster in swarm mode as explained [here](https://github.com/ivangfr/docker-swarm-environment#initializing-a-cluster-of-docker-engines-in-swarm-mode)

## Clone repository

Clone [`spring-cloud-stream-elasticsearch`](https://github.com/ivangfr/spring-cloud-stream-elasticsearch)
```
git clone https://github.com/ivangfr/spring-cloud-stream-elasticsearch.git
```

## Build Docker Images

Instead of pushing the applications docker images to Docker Registry, we will simply build them using `manager1` and `worker1` Docker daemons.

Let's start with `worker1`. Open a terminal and run
```
eval $(docker-machine env worker1)
```

> **Note:** to get back to the Docker Daemon of the Host machine run
> ```
> eval $(docker-machine env -u)
> ```

Then, inside `spring-cloud-stream-elasticsearch` root folder run
```
./build-apps.sh
```

Let's do the same for the `manager1` machine
```
eval $(docker-machine env manager1)
```

Finally, inside `spring-cloud-stream-elasticsearch` root folder run
```
./build-apps.sh
```

Once it is finished, we can check that all docker images were created and are present in the `manager1` machine, by running
```
docker images
```

## Deploy Example

Before starting, let's set the `manager1` Docker Daemon
```
eval $(docker-machine env manager1)
```

Then, let's deploy the infrastructure services. For it, inside `docker-swarm-environment/news-pipeline` folder run
```
./deploy-infra-services.sh
```

We can list the status of the infrastructure services by running
```
docker service ls
```

It will prompt something like
```
ID                  NAME                MODE                REPLICAS            IMAGE                                                     PORTS
a54qs4pn56n9        elasticsearch       replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch-oss:6.4.2   *:9200->9200/tcp, *:9300->9300/tcp
v03mxbdfaj8r        kafka               replicated          1/1                 confluentinc/cp-kafka:5.3.1                               *:29092->29092/tcp
wm1n76gg299g        zipkin              replicated          1/1                 openzipkin/zipkin:2.18.0                                  *:9411->9411/tcp
nkqcoz198z8f        zookeeper           replicated          1/1                 confluentinc/cp-zookeeper:5.3.1                           *:2181->2181/tcp
```

Once all infrastructure are up running, let's deploy the applications
```
./deploy-apps.sh
```

To list the status of the infrastructure services and applications run
```
docker service ls
```

You should see something like
```
ID                  NAME                  MODE                REPLICAS            IMAGE                                                     PORTS
rf4vvsf0oy4m        categorizer-service   replicated          1/1                 docker.mycompany.com/categorizer-service:1.0.0            *:9081->8080/tcp
itjgeyeys1ux        collector-service     replicated          1/1                 docker.mycompany.com/collector-service:1.0.0              *:9082->8080/tcp
a54qs4pn56n9        elasticsearch         replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch-oss:6.4.2   *:9200->9200/tcp, *:9300->9300/tcp
lvdvvf0ec9dc        eureka                replicated          1/1                 docker.mycompany.com/eureka-server:1.0.0                  *:8761->8761/tcp
v03mxbdfaj8r        kafka                 replicated          1/1                 confluentinc/cp-kafka:5.3.1                               *:29092->29092/tcp
m7bhkd4nisol        news-client           replicated          1/1                 docker.mycompany.com/news-client:1.0.0                    *:8080->8080/tcp
pcqql3rzlm7o        producer-api          replicated          1/1                 docker.mycompany.com/producer-api:1.0.0                   *:9080->8080/tcp
oprcfi3ytb72        publisher-api         replicated          1/1                 docker.mycompany.com/publisher-api:1.0.0                  *:9083->8080/tcp
wm1n76gg299g        zipkin                replicated          1/1                 openzipkin/zipkin:2.18.0                                  *:9411->9411/tcp
nkqcoz198z8f        zookeeper             replicated          1/1                 confluentinc/cp-zookeeper:5.3.1                           *:2181->2181/tcp
```

To check more information about specific service, for example `elasticsearch`, run
```
docker service ps elasticsearch
```

We can also check the logs of a specific service, for instance `producer-api`, by running
```
docker service logs producer-api
```

To scale the `news-client` service to 2 replicas, run
```
docker service scale news-client=2
```

## Applications & Services URLs

To get the URLs run
```
./get-services-urls.sh
```

You should see something like
```
       Service |                                        URL |
-------------- + ------------------------------------------ |
  producer-api | http://192.168.99.116:9080/swagger-ui.html |
 publisher-api | http://192.168.99.116:9083/swagger-ui.html |
   news-client |                 http://192.168.99.116:8080 |
        eureka |                 http://192.168.99.116:8761 |
        zipkin |                 http://192.168.99.116:9411 |
 elasticsearch |                 http://192.168.99.116:9200 |
```

## Shutdown

Just run the following scripts
```
./remove-apps.sh
./remove-infra-services.sh
```
