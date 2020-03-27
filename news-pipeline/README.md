# docker-swarm-environment
## `>` news-pipeline

In this example, we are going to deploy, into a cluster of Docker Engines in swarm mode, the applications present in the repository [`spring-cloud-stream-elasticsearch`](https://github.com/ivangfr/spring-cloud-stream-elasticsearch)

So, let's start the Docker Engines cluster in swarm mode as explained in the main [README](https://github.com/ivangfr/docker-swarm-environment#initializing-a-cluster-of-docker-engines-in-swarm-mode)

## Clone repository

Clone [`spring-cloud-stream-elasticsearch`](https://github.com/ivangfr/spring-cloud-stream-elasticsearch)
```
git clone https://github.com/ivangfr/spring-cloud-stream-elasticsearch.git
```

## Build Docker Images

Instead of pushing the applications docker images to Docker Registry, we will simply build them using `manager1` and `worker1` Docker daemons. Below are the steps

- In a terminal, navigate to `spring-cloud-stream-elasticsearch` root folder

- Access `worker1` Docker Daemon
  ```
  eval $(docker-machine env worker1)
  ```

- Build application's docker images
  ```
  ./build-apps.sh
  ```

- Access `manager1` Docker Daemon
  ```
  eval $(docker-machine env manager1)
  ```

- Build again application's docker images
  ```
  ./build-apps.sh
  ```
   
- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```

## Deploy Example

- In a terminal, navigate to `docker-swarm-environment/news-pipeline` folder

- Access `manager1` Docker Daemon
  ```
  eval $(docker-machine env manager1)
  ```

- Deploy the infrastructure services
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
  v03mxbdfaj8r        kafka               replicated          1/1                 confluentinc/cp-kafka:5.4.1                               *:29092->29092/tcp
  wm1n76gg299g        zipkin              replicated          1/1                 openzipkin/zipkin:2.20.2                                  *:9411->9411/tcp
  nkqcoz198z8f        zookeeper           replicated          1/1                 confluentinc/cp-zookeeper:5.4.1                           *:2181->2181/tcp
  ```

- Once all infrastructure services are up running, let's deploy the applications
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
  v03mxbdfaj8r        kafka                 replicated          1/1                 confluentinc/cp-kafka:5.4.1                               *:29092->29092/tcp
  m7bhkd4nisol        news-client           replicated          1/1                 docker.mycompany.com/news-client:1.0.0                    *:8080->8080/tcp
  pcqql3rzlm7o        producer-api          replicated          1/1                 docker.mycompany.com/producer-api:1.0.0                   *:9080->8080/tcp
  oprcfi3ytb72        publisher-api         replicated          1/1                 docker.mycompany.com/publisher-api:1.0.0                  *:9083->8080/tcp
  wm1n76gg299g        zipkin                replicated          1/1                 openzipkin/zipkin:2.20.2                                  *:9411->9411/tcp
  nkqcoz198z8f        zookeeper             replicated          1/1                 confluentinc/cp-zookeeper:5.4.1                           *:2181->2181/tcp
  ```

- \[Optional\] To check more information about specific service, for example `news-client`
  ```
  docker service ps news-client
  ```

- \[Optional\] To check the logs of a specific service, for instance `news-client`
  ```
  docker service logs news-client
  ```

- \[Optional\] To scale the `news-client` service to 2 replicas
  ```
  docker service scale news-client=2
  ```
   
- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```

## Applications & Services URLs

- In a terminal, make sure you are inside `docker-swarm-environment/news-pipeline` folder

- Run the script below to get the services URLs
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

- In a terminal, make sure you are inside `docker-swarm-environment/news-pipeline` folder

- Set `manager1` Docker Daemon
  ```
  eval $(docker-machine env manager1)
  ```

- Run the following scripts
  ```
  ./remove-apps.sh && ./remove-infra-services.sh
  ```
  
- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```
  
## Issues

- It seems that there is some problem with Feign or Eureka because `news-client` is trying to make a request to `publisher-api` (`http://publisher-api/api/news?sort=datetime%2Cdesc`) and it's failing.
  ```
  news-client.1.w0yk93k04xvh@worker1    | 2020-03-27 16:03:03.321 ERROR [news-client,15871894559932e6,15871894559932e6,true] 1 --- [nio-8080-exec-4] o.s.c.s.i.web.ExceptionLoggingFilter     : Uncaught exception thrown
  news-client.1.w0yk93k04xvh@worker1    |
  news-client.1.w0yk93k04xvh@worker1    | org.springframework.web.util.NestedServletException: Request processing failed; nested exception is feign.RetryableException: connect timed out executing GET http://publisher-api/api/news?sort=datetime%2Cdesc
  ```
  
  If the port `8080` was informed, it'd work. For example
  ```
  $ docker exec -it news-client.2.jssrxjunyz3d97h53n1u5p8hk sh
  
  / # curl -i publisher-api/api/news?sort=datetime%2Cdesc
  curl: (7) Failed to connect to publisher-api port 80: Connection refused
  
  / # curl -i publisher-api:8080/api/news?sort=datetime%2Cdesc
  HTTP/1.1 200
  Content-Type: application/json
  Transfer-Encoding: chunked
  Date: Fri, 27 Mar 2020 17:15:31 GMT
  
  {"content":[],"pageable":{"sort":{"sorted":true,"unsorted":false,"empty":false},"pageNumber":0,"pageSize":20,"offset":0,"paged":true,"unpaged":false},"facets":[],"aggregations":null,"scrollId":null,"maxScore":"NaN","totalElements":0,"totalPages":0,"sort":{"sorted":true,"unsorted":false,"empty":false},"numberOfElements":0,"last":true,"first":true,"size":20,"number":0,"empty":true}
  ```