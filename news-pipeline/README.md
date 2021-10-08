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
  ./docker-build.sh
  ```

- Access `manager1` Docker Daemon
  ```
  eval $(docker-machine env manager1)
  ```

- Build again application's docker images
  ```
  ./docker-build.sh
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

  We can list the infrastructure services by running
  ```
  docker service ls
  ```

  It will prompt something like
  ```
  ID             NAME              MODE         REPLICAS   IMAGE                                                  PORTS
  cp3ta9nw4afa   elasticsearch     replicated   1/1        docker.elastic.co/elasticsearch/elasticsearch:7.12.1   *:9200->9200/tcp, *:9300->9300/tcp
  lgb2a66pz99m   kafka             replicated   1/1        confluentinc/cp-kafka:6.1.1                            *:29092->29092/tcp
  a4vp97ahjuss   schema-registry   replicated   1/1        confluentinc/cp-schema-registry:6.1.1                  *:8081->8081/tcp
  dj18duum1wia   zipkin            replicated   1/1        openzipkin/zipkin:2.21.5                               *:9411->9411/tcp
  wkdfpar379yj   zookeeper         replicated   1/1        confluentinc/cp-zookeeper:6.1.1                        *:2181->2181/tcp
  ```

- Once all infrastructure services are up running, let's deploy the applications
  ```
  ./deploy-apps.sh
  ```

  Listing infrastructure services and applications
  ```
  docker service ls
  ```

  You should see something like
  ```
  ID             NAME                  MODE         REPLICAS   IMAGE                                                  PORTS
  m6lfe0ybmvlz   categorizer-service   replicated   1/1        ivanfranchin/categorizer-service:1.0.0                 *:9081->8080/tcp
  6pi3tb3h67bq   collector-service     replicated   1/1        ivanfranchin/collector-service:1.0.0                   *:9082->8080/tcp
  cp3ta9nw4afa   elasticsearch         replicated   1/1        docker.elastic.co/elasticsearch/elasticsearch:7.12.1   *:9200->9200/tcp, *:9300->9300/tcp
  wtr6nu7ox1vv   eureka                replicated   1/1        ivanfranchin/eureka-server:1.0.0                       *:8761->8761/tcp
  lgb2a66pz99m   kafka                 replicated   1/1        confluentinc/cp-kafka:6.1.1                            *:29092->29092/tcp
  rs3wity2bjx6   news-client           replicated   1/1        ivanfranchin/news-client:1.0.0                         *:8080->8080/tcp
  8utmrqu063bu   producer-api          replicated   1/1        ivanfranchin/producer-api:1.0.0                        *:9080->8080/tcp
  nj7xlp4bsujl   publisher-api         replicated   1/1        ivanfranchin/publisher-api:1.0.0                       *:9083->8080/tcp
  a4vp97ahjuss   schema-registry       replicated   1/1        confluentinc/cp-schema-registry:6.1.1                  *:8081->8081/tcp
  dj18duum1wia   zipkin                replicated   1/1        openzipkin/zipkin:2.21.5                               *:9411->9411/tcp
  wkdfpar379yj   zookeeper             replicated   1/1        confluentinc/cp-zookeeper:6.1.1                        *:2181->2181/tcp                           *:2181->2181/tcp
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
  ./remove-apps.sh
  ./remove-infra-services.sh
  ```
  
- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```
  
## Issues

- It seems that there is some problem with `Feign` or `Eureka` because `news-client` is trying to make a request to `publisher-api` (`http://publisher-api/api/news?sort=datetime%2Cdesc`) and it's failing.
  ```
  news-client.1.fnkpagzruezr@manager1    | 2021-10-08 09:20:11.703 ERROR [news-client,,] 1 --- [nio-8080-exec-3] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is feign.RetryableException: connect timed out executing GET http://publisher-api/api/news?sort=datetime%2Cdesc] with root cause
  ...
  <full log below>
  ```
  
  If the port `8080` was informed, it'd work.
  
  For example
  ```
  $ docker exec -it news-client.1.fnkpagzruezrnzkz9z4k5nnqi sh
  
  / # curl -i publisher-api/api/news?sort=datetime%2Cdesc
  curl: (7) Failed to connect to publisher-api port 80: Connection refused
  
  / # curl -i publisher-api:8080/api/news?sort=datetime%2Cdesc
  HTTP/1.1 200
  Content-Type: application/json
  ...
  
  {"content":[],"pageable":{"sort":{"sorted":true,"unsorted":false,"empty":false},"pageNumber":0,"pageSize":20,"offset":0,"paged":true,"unpaged":false},"facets":[],"aggregations":null,"scrollId":null,"maxScore":"NaN","totalElements":0,"totalPages":0,"sort":{"sorted":true,"unsorted":false,"empty":false},"numberOfElements":0,"last":true,"first":true,"size":20,"number":0,"empty":true}
  ```
  
  ---
  ```
  news-client.1.fnkpagzruezr@manager1    | java.net.SocketTimeoutException: connect timed out
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.net.PlainSocketImpl.socketConnect(Native Method) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.net.AbstractPlainSocketImpl.doConnect(AbstractPlainSocketImpl.java:399) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.net.AbstractPlainSocketImpl.connectToAddress(AbstractPlainSocketImpl.java:242) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.net.AbstractPlainSocketImpl.connect(AbstractPlainSocketImpl.java:224) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.net.Socket.connect(Socket.java:609) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.NetworkClient.doConnect(NetworkClient.java:177) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.http.HttpClient.openServer(HttpClient.java:474) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.http.HttpClient.openServer(HttpClient.java:569) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.http.HttpClient.<init>(HttpClient.java:242) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.http.HttpClient.New(HttpClient.java:341) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.http.HttpClient.New(HttpClient.java:362) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.getNewHttpClient(HttpURLConnection.java:1253) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.plainConnect0(HttpURLConnection.java:1187) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.plainConnect(HttpURLConnection.java:1081) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.connect(HttpURLConnection.java:1015) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1592) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1520) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.net.HttpURLConnection.getResponseCode(HttpURLConnection.java:527) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at feign.Client$Default.convertResponse(Client.java:108) ~[feign-core-10.12.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at feign.Client$Default.execute(Client.java:104) ~[feign-core-10.12.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.client.feign.TracingFeignClient.execute(TracingFeignClient.java:79) ~[spring-cloud-sleuth-instrumentation-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.client.feign.LazyTracingFeignClient.execute(LazyTracingFeignClient.java:62) ~[spring-cloud-sleuth-instrumentation-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.openfeign.loadbalancer.LoadBalancerUtils.executeWithLoadBalancerLifecycleProcessing(LoadBalancerUtils.java:56) ~[spring-cloud-openfeign-core-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.openfeign.loadbalancer.RetryableFeignBlockingLoadBalancerClient.lambda$execute$2(RetryableFeignBlockingLoadBalancerClient.java:156) ~[spring-cloud-openfeign-core-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.retry.support.RetryTemplate.doExecute(RetryTemplate.java:329) ~[spring-retry-1.3.1.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.retry.support.RetryTemplate.execute(RetryTemplate.java:225) ~[spring-retry-1.3.1.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.openfeign.loadbalancer.RetryableFeignBlockingLoadBalancerClient.execute(RetryableFeignBlockingLoadBalancerClient.java:103) ~[spring-cloud-openfeign-core-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.client.feign.TraceRetryableFeignBlockingLoadBalancerClient.execute(TraceRetryableFeignBlockingLoadBalancerClient.java:79) ~[spring-cloud-sleuth-instrumentation-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at feign.SynchronousMethodHandler.executeAndDecode(SynchronousMethodHandler.java:119) ~[feign-core-10.12.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at feign.SynchronousMethodHandler.invoke(SynchronousMethodHandler.java:89) ~[feign-core-10.12.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at feign.ReflectiveFeign$FeignInvocationHandler.invoke(ReflectiveFeign.java:100) ~[feign-core-10.12.jar:na]
  news-client.1.fnkpagzruezr@manager1    | 	at com.sun.proxy.$Proxy157.listNewsByPage(Unknown Source) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at com.mycompany.newsclient.controller.NewsController.getNews(NewsController.java:29) ~[classes/:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.lang.reflect.Method.invoke(Method.java:566) ~[na:na]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:205) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:150) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:117) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:895) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:808) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1067) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:963) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1006) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:898) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at javax.servlet.http.HttpServlet.service(HttpServlet.java:655) ~[tomcat-embed-core-9.0.53.jar:4.0.FR]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:883) ~[spring-webmvc-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at javax.servlet.http.HttpServlet.service(HttpServlet.java:764) ~[tomcat-embed-core-9.0.53.jar:4.0.FR]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:227) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:53) ~[tomcat-embed-websocket-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:189) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.RequestContextFilter.doFilterInternal(RequestContextFilter.java:100) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:189) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.FormContentFilter.doFilterInternal(FormContentFilter.java:93) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:189) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.sleuth.instrument.web.servlet.TracingFilter.doFilter(TracingFilter.java:89) ~[spring-cloud-sleuth-instrumentation-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.cloud.sleuth.autoconfig.instrument.web.LazyTracingFilter.doFilter(TraceWebServletConfiguration.java:114) ~[spring-cloud-sleuth-autoconfigure-3.0.4.jar:3.0.4]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:189) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.boot.actuate.metrics.web.servlet.WebMvcMetricsFilter.doFilterInternal(WebMvcMetricsFilter.java:96) ~[spring-boot-actuator-2.5.5.jar:2.5.5]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:189) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.CharacterEncodingFilter.doFilterInternal(CharacterEncodingFilter.java:201) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:119) ~[spring-web-5.3.10.jar:5.3.10]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:189) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:162) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:197) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:97) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:540) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:135) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:92) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:78) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:357) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.coyote.http11.Http11Processor.service(Http11Processor.java:382) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.coyote.AbstractProcessorLight.process(AbstractProcessorLight.java:65) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.coyote.AbstractProtocol$ConnectionHandler.process(AbstractProtocol.java:893) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1726) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.tomcat.util.net.SocketProcessorBase.run(SocketProcessorBase.java:49) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.tomcat.util.threads.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1191) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.tomcat.util.threads.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:659) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61) ~[tomcat-embed-core-9.0.53.jar:9.0.53]
  news-client.1.fnkpagzruezr@manager1    | 	at java.base/java.lang.Thread.run(Thread.java:829) ~[na:na]  
  ```