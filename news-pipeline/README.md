# docker-swarm-environment
## `> news-pipeline`

In this example, we are going to deploy, into a cluster of Docker Engines in swarm mode, the applications present in the repository [`spring-cloud-stream-kafka-elasticsearch`](https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch)

So, let's start a Docker Engines cluster in swarm mode as explained in the main [README](https://github.com/ivangfr/docker-swarm-environment#initializing-a-cluster-of-docker-engines-in-swarm-mode)

## Clone repository

In a terminal, run the following command to clone [`spring-cloud-stream-kafka-elasticsearch`](https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch)
```
git clone https://github.com/ivangfr/spring-cloud-stream-kafka-elasticsearch.git
```

## Prerequisite

- [`Java 11+`](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
- [`jq`](https://stedolan.github.io/jq)

## Build Docker Images

Instead of pushing the application's docker image to Docker Registry, we will simply build them using `manager1` and `worker1` Docker daemons. Below are the steps

- In a terminal, navigate to `spring-cloud-stream-kafka-elasticsearch` root folder

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
  a0iaiy6fqux1        elasticsearch       replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch-oss:7.6.2   *:9200->9200/tcp, *:9300->9300/tcp
  ewbx5uin498i        kafka               replicated          1/1                 confluentinc/cp-kafka:5.5.1                               *:29092->29092/tcp
  qcaohujo2xcr        schema-registry     replicated          1/1                 confluentinc/cp-schema-registry:5.5.1                     *:8081->8081/tcp
  xoxy3tefq6e5        zipkin              replicated          1/1                 openzipkin/zipkin:2.20.2                                  *:9411->9411/tcp
  3hf85j94lg61        zookeeper           replicated          1/1                 confluentinc/cp-zookeeper:5.5.1                           *:2181->2181/tcp
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
  u771bk2a35gq        categorizer-service   replicated          1/1                 docker.mycompany.com/categorizer-service:1.0.0            *:9081->8080/tcp
  84mgv1omezn4        collector-service     replicated          1/1                 docker.mycompany.com/collector-service:1.0.0              *:9082->8080/tcp
  a0iaiy6fqux1        elasticsearch         replicated          1/1                 docker.elastic.co/elasticsearch/elasticsearch-oss:7.6.2   *:9200->9200/tcp, *:9300->9300/tcp
  ep84gglkkyk5        eureka                replicated          1/1                 docker.mycompany.com/eureka-server:1.0.0                  *:8761->8761/tcp
  ewbx5uin498i        kafka                 replicated          1/1                 confluentinc/cp-kafka:5.5.1                               *:29092->29092/tcp
  jniy78jg7bbk        news-client           replicated          1/1                 docker.mycompany.com/news-client:1.0.0                    *:8080->8080/tcp
  2ugkvpf37al4        producer-api          replicated          1/1                 docker.mycompany.com/producer-api:1.0.0                   *:9080->8080/tcp
  pfym6ayoru2h        publisher-api         replicated          1/1                 docker.mycompany.com/publisher-api:1.0.0                  *:9083->8080/tcp
  qcaohujo2xcr        schema-registry       replicated          1/1                 confluentinc/cp-schema-registry:5.5.1                     *:8081->8081/tcp
  xoxy3tefq6e5        zipkin                replicated          1/1                 openzipkin/zipkin:2.20.2                                  *:9411->9411/tcp
  3hf85j94lg61        zookeeper             replicated          1/1                 confluentinc/cp-zookeeper:5.5.1                           *:2181->2181/tcp
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
          Service |                                       URL |
  --------------- + ----------------------------------------- |
     producer-api | http://<manager1-ip>:9080/swagger-ui.html |
    publisher-api | http://<manager1-ip>:9083/swagger-ui.html |
      news-client |                 http://<manager1-ip>:8080 |
           eureka |                 http://<manager1-ip>:8761 |
           zipkin |                 http://<manager1-ip>:9411 |
    elasticsearch |                 http://<manager1-ip>:9200 |
  schema-registry |                 http://<manager1-ip>:8081 |
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

- It seems that there is some problem with `Feign` or `Eureka` because `news-client` is trying to make a request to `publisher-api` (`http://publisher-api/api/news?sort=datetime%2Cdesc`) and it's failing.
  ```
  news-client.1.mwy3tw2lx2lh@manager1    | 2020-07-08 16:58:14.824 ERROR [news-client,,,] 1 --- [nio-8080-exec-5] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is feign.RetryableException: connect timed out executing GET http://publisher-api/api/news?sort=datetime%2Cdesc] with root cause
  ...
  <full log below>
  ```
  
  If the port `8080` was informed, it'd work.
  
  For example
  ```
  $ docker exec -it news-client.1.mwy3tw2lx2lhdaw15j7s0helr sh
  
  / # curl -i publisher-api/api/news?sort=datetime%2Cdesc
  curl: (7) Failed to connect to publisher-api port 80: Connection refused
  
  / # curl -i publisher-api:8080/api/news?sort=datetime%2Cdesc
  HTTP/1.1 200
  Content-Type: application/json
  Transfer-Encoding: chunked
  Date: Fri, 27 Mar 2020 17:15:31 GMT
  
  {"content":[],"pageable":{"sort":{"sorted":true,"unsorted":false,"empty":false},"pageNumber":0,"pageSize":20,"offset":0,"paged":true,"unpaged":false},"facets":[],"aggregations":null,"scrollId":null,"maxScore":"NaN","totalElements":0,"totalPages":0,"sort":{"sorted":true,"unsorted":false,"empty":false},"numberOfElements":0,"last":true,"first":true,"size":20,"number":0,"empty":true}
  ```
  
  ---
  ```
  news-client.1.mwy3tw2lx2lh@manager1    | 2020-07-08 16:58:14.824 ERROR [news-client,,,] 1 --- [nio-8080-exec-5] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is feign.RetryableException: connect timed out executing GET http://publisher-api/api/news?sort=datetime%2Cdesc] with root cause
  news-client.1.mwy3tw2lx2lh@manager1    |
  news-client.1.mwy3tw2lx2lh@manager1    | java.net.SocketTimeoutException: connect timed out
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.net.PlainSocketImpl.socketConnect(Native Method) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:399) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:242) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:224) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.net.Socket.connect(Socket.java:609) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.NetworkClient.doConnect(NetworkClient.java:177) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.http.HttpClient.openServer(HttpClient.java:474) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.http.HttpClient.openServer(HttpClient.java:569) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.http.HttpClient.<init>(HttpClient.java:242) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.http.HttpClient.New(HttpClient.java:341) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.http.HttpClient.New(HttpClient.java:362) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.getNewHttpClient(HttpURLConnection.java:1248) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.plainConnect0(HttpURLConnection.java:1187) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.plainConnect(HttpURLConnection.java:1081) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.connect(HttpURLConnection.java:1015) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1587) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1515) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.net.HttpURLConnection.getResponseCode(HttpURLConnection.java:527) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at feign.Client$Default.convertResponse(Client.java:108) ~[feign-core-10.10.1.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at feign.Client$Default.execute(Client.java:104) ~[feign-core-10.10.1.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.client.feign.TracingFeignClient.execute(TracingFeignClient.java:81) ~[spring-cloud-sleuth-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.client.feign.LazyTracingFeignClient.execute(LazyTracingFeignClient.java:60) ~[spring-cloud-sleuth-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.openfeign.ribbon.RetryableFeignLoadBalancer$1.doWithRetry(RetryableFeignLoadBalancer.java:114) ~[spring-cloud-openfeign-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.openfeign.ribbon.RetryableFeignLoadBalancer$1.doWithRetry(RetryableFeignLoadBalancer.java:94) ~[spring-cloud-openfeign-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.retry.support.RetryTemplate.doExecute(RetryTemplate.java:287) ~[spring-retry-1.2.5.RELEASE.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.retry.support.RetryTemplate.execute(RetryTemplate.java:180) ~[spring-retry-1.2.5.RELEASE.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.openfeign.ribbon.RetryableFeignLoadBalancer.execute(RetryableFeignLoadBalancer.java:94) ~[spring-cloud-openfeign-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.openfeign.ribbon.RetryableFeignLoadBalancer.execute(RetryableFeignLoadBalancer.java:54) ~[spring-cloud-openfeign-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.netflix.client.AbstractLoadBalancerAwareClient$1.call(AbstractLoadBalancerAwareClient.java:104) ~[ribbon-loadbalancer-2.3.0.jar:2.3.0]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.netflix.loadbalancer.reactive.LoadBalancerCommand$3$1.call(LoadBalancerCommand.java:303) ~[ribbon-loadbalancer-2.3.0.jar:2.3.0]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.netflix.loadbalancer.reactive.LoadBalancerCommand$3$1.call(LoadBalancerCommand.java:287) ~[ribbon-loadbalancer-2.3.0.jar:2.3.0]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.util.ScalarSynchronousObservable$3.call(ScalarSynchronousObservable.java:231) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.util.ScalarSynchronousObservable$3.call(ScalarSynchronousObservable.java:228) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.Observable.unsafeSubscribe(Observable.java:10327) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeConcatMap$ConcatMapSubscriber.drain(OnSubscribeConcatMap.java:286) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeConcatMap$ConcatMapSubscriber.onNext(OnSubscribeConcatMap.java:144) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.netflix.loadbalancer.reactive.LoadBalancerCommand$1.call(LoadBalancerCommand.java:185) ~[ribbon-loadbalancer-2.3.0.jar:2.3.0]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.netflix.loadbalancer.reactive.LoadBalancerCommand$1.call(LoadBalancerCommand.java:180) ~[ribbon-loadbalancer-2.3.0.jar:2.3.0]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.Observable.unsafeSubscribe(Observable.java:10327) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeConcatMap.call(OnSubscribeConcatMap.java:94) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeConcatMap.call(OnSubscribeConcatMap.java:42) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.Observable.unsafeSubscribe(Observable.java:10327) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OperatorRetryWithPredicate$SourceSubscriber$1.call(OperatorRetryWithPredicate.java:127) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.schedulers.TrampolineScheduler$InnerCurrentThreadScheduler.enqueue(TrampolineScheduler.java:73) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.schedulers.TrampolineScheduler$InnerCurrentThreadScheduler.schedule(TrampolineScheduler.java:52) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OperatorRetryWithPredicate$SourceSubscriber.onNext(OperatorRetryWithPredicate.java:79) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OperatorRetryWithPredicate$SourceSubscriber.onNext(OperatorRetryWithPredicate.java:45) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.util.ScalarSynchronousObservable$WeakSingleProducer.request(ScalarSynchronousObservable.java:276) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.Subscriber.setProducer(Subscriber.java:209) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.util.ScalarSynchronousObservable$JustOnSubscribe.call(ScalarSynchronousObservable.java:138) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.util.ScalarSynchronousObservable$JustOnSubscribe.call(ScalarSynchronousObservable.java:129) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeLift.call(OnSubscribeLift.java:48) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeLift.call(OnSubscribeLift.java:30) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeLift.call(OnSubscribeLift.java:48) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeLift.call(OnSubscribeLift.java:30) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeLift.call(OnSubscribeLift.java:48) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.internal.operators.OnSubscribeLift.call(OnSubscribeLift.java:30) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.Observable.subscribe(Observable.java:10423) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.Observable.subscribe(Observable.java:10390) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.observables.BlockingObservable.blockForSingle(BlockingObservable.java:443) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at rx.observables.BlockingObservable.single(BlockingObservable.java:340) ~[rxjava-1.3.8.jar:1.3.8]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.netflix.client.AbstractLoadBalancerAwareClient.executeWithLoadBalancer(AbstractLoadBalancerAwareClient.java:112) ~[ribbon-loadbalancer-2.3.0.jar:2.3.0]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.openfeign.ribbon.LoadBalancerFeignClient.execute(LoadBalancerFeignClient.java:83) ~[spring-cloud-openfeign-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.client.feign.TraceLoadBalancerFeignClient.execute(TraceLoadBalancerFeignClient.java:78) ~[spring-cloud-sleuth-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at feign.SynchronousMethodHandler.executeAndDecode(SynchronousMethodHandler.java:119) ~[feign-core-10.10.1.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at feign.SynchronousMethodHandler.invoke(SynchronousMethodHandler.java:89) ~[feign-core-10.10.1.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at feign.ReflectiveFeign$FeignInvocationHandler.invoke(ReflectiveFeign.java:100) ~[feign-core-10.10.1.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.sun.proxy.$Proxy159.listNewsByPage(Unknown Source) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at com.mycompany.newsclient.controller.NewsController.getNews(NewsController.java:29) ~[classes/:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.lang.reflect.Method.invoke(Method.java:566) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:190) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:138) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:105) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:879) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:793) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1040) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:943) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1006) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:898) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at javax.servlet.http.HttpServlet.service(HttpServlet.java:634) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:883) ~[spring-webmvc-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at javax.servlet.http.HttpServlet.service(HttpServlet.java:741) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:231) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:53) ~[tomcat-embed-websocket-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at brave.servlet.TracingFilter.doFilter(TracingFilter.java:68) ~[brave-instrumentation-servlet-5.12.3.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.RequestContextFilter.doFilterInternal(RequestContextFilter.java:100) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.FormContentFilter.doFilterInternal(FormContentFilter.java:93) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at brave.servlet.TracingFilter.doFilter(TracingFilter.java:87) ~[brave-instrumentation-servlet-5.12.3.jar:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.LazyTracingFilter.doFilter(TraceWebServletAutoConfiguration.java:139) ~[spring-cloud-sleuth-core-2.2.3.RELEASE.jar:2.2.3.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.boot.actuate.metrics.web.servlet.WebMvcMetricsFilter.doFilterInternal(WebMvcMetricsFilter.java:93) ~[spring-boot-actuator-2.3.1.RELEASE.jar:2.3.1.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:201) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.2.7.RELEASE.jar:5.2.7.RELEASE]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:166) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:202) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:96) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:541) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:139) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:92) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:74) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:343) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.coyote.http11.Http11Processor.service(Http11Processor.java:373) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.coyote.AbstractProcessorLight.process(AbstractProcessorLight.java:65) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.coyote.AbstractProtocol$ConnectionHandler.process(AbstractProtocol.java:868) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1590) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.tomcat.util.net.SocketProcessorBase.run(SocketProcessorBase.java:49) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) ~[tomcat-embed-core-9.0.36.jar:9.0.36]
  news-client.1.mwy3tw2lx2lh@manager1    | 	at java.base/java.lang.Thread.run(Thread.java:834) ~[na:na]
  news-client.1.mwy3tw2lx2lh@manager1    |
  ```