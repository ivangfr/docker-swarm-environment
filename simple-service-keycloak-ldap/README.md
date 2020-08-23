# docker-swarm-environment
## `> simple-service-keycloak-ldap`

In this example, we are going to deploy, into a cluster of Docker Engines in swarm mode, the applications present in the repository [`springboot-keycloak-openldap`](https://github.com/ivangfr/springboot-keycloak-openldap).

So, let's start a Docker Engines cluster in swarm mode as explained in the main [README](https://github.com/ivangfr/docker-swarm-environment#initializing-a-cluster-of-docker-engines-in-swarm-mode)

## Clone repository

In a terminal, run the following command to clone [`springboot-keycloak-openldap`](https://github.com/ivangfr/springboot-keycloak-openldap) repository
```
git clone https://github.com/ivangfr/springboot-keycloak-openldap.git
```

## Prerequisite

- [`Java 11+`](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
- [`jq`](https://stedolan.github.io/jq)

## Build simple-service docker image

Instead of pushing `simple-service` docker image to Docker Registry, we will simply build it using `manager1` and `worker1` Docker daemons.

- In a terminal, navigate to `springboot-keycloak-openldap` root folder

- Access `worker1` Docker Daemon
  ```
  eval $(docker-machine env worker1)
  ```

- Build `simple-service` docker image
  ```
  ./mvnw clean compile jib:dockerBuild --projects simple-service
  ```

- Access `manager1` Docker Daemon
  ```
  eval $(docker-machine env manager1)
  ```
   
- Build again `simple-service` docker image
  ```
  ./mvnw clean compile jib:dockerBuild --projects simple-service
  ```

- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```

## Deploy Example

- In a terminal, navigate to `docker-swarm-environment/simple-service-keycloak-ldap` folder

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
  ID                  NAME                   MODE                REPLICAS            IMAGE                                    PORTS
  vfyq79g15htf        keycloak               replicated          2/2                 ivanfranchin/keycloak-clustered:10.0.2   *:8080->8080/tcp
  it87nfuo7jd8        ldap-host              replicated          1/1                 osixia/openldap:1.3.0                    *:389->389/tcp
  tinqjr9fwjn5        mysql                  replicated          1/1                 mysql:5.7.30                             *:3306->3306/tcp
  qil9rhadw94k        phpldapadmin-service   replicated          1/1                 osixia/phpldapadmin:0.9.0                *:6443->443/tcp
  ```

- Once all infrastructure services are up and running, let's deploy `simple-service` application
  ```
  ./deploy-app.sh
  ```

  To list the status of the infrastructure services and `simple-service` application run
  ```
  docker service ls
  ```
   
  You should see something like
  ```
  ID                  NAME                   MODE                REPLICAS            IMAGE                                       PORTS
  vfyq79g15htf        keycloak               replicated          2/2                 ivanfranchin/keycloak-clustered:10.0.2      *:8080->8080/tcp
  it87nfuo7jd8        ldap-host              replicated          1/1                 osixia/openldap:1.3.0                       *:389->389/tcp
  tinqjr9fwjn5        mysql                  replicated          1/1                 mysql:5.7.30                                *:3306->3306/tcp
  qil9rhadw94k        phpldapadmin-service   replicated          1/1                 osixia/phpldapadmin:0.9.0                   *:6443->443/tcp
  41xn7k500sti        simple-service         replicated          1/1                 docker.mycompany.com/simple-service:1.0.0   *:9080->8080/tcp
  ```

- \[Optional\] In order to see the `simple-service` initialization logs
  ```
  docker service logs simple-service
  ```

- \[Optional\] To check more information about specific service, for example `keycloak`, run
  ```
  docker service ps keycloak
  ```

- \[Optional\] To scale the `simple-service` service to 2 replicas, run
  ```
  docker service scale simple-service=2
  ```

- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```

## Application & Services URLs

- In a terminal, make sure you are inside `docker-swarm-environment/simple-service-keycloak-ldap` folder

- Run the script below to get the services URLs
  ```
  ./get-services-urls.sh
  ```

  You should see something like
  ```
          Service |                                       URL |                        Credentials |
  --------------- + ----------------------------------------- + ---------------------------------- |
   simple-service | http://<manager1-ip>:9080/swagger-ui.html |                                    |
         keycloak |                 http://<manager1-ip>:8080 |                        admin/admin |
     phpldapadmin |                https://<manager1-ip>:6443 | cn=admin,dc=mycompany,dc=com/admin |
  ```

## Import OpenLDAP Users

The `LDIF` file that we will use, `springboot-keycloak-openldap/ldap/ldap-mycompany-com.ldif`, contains a pre-defined structure for `mycompany.com`. Basically, it has 2 groups (`developers` and `admin`) and 4 users (`Bill Gates`, `Steve Jobs`, `Mark Cuban` and `Ivan Franchin`). Besides, it's defined that `Bill Gates`, `Steve Jobs` and `Mark Cuban` belong to `developers` group and `Ivan Franchin` belongs to `admin` group.
```
Bill Gates > username: bgates, password: 123
Steve Jobs > username: sjobs, password: 123
Mark Cuban > username: mcuban, password: 123
Ivan Franchin > username: ifranchin, password: 123
```

- In a terminal, make sure you are in `springboot-keycloak-openldap` root folder

- Run the following script
  ```
  ./import-openldap-users.sh $(docker-machine ip manager1)
  ```

> **Note:** The import of the users can also be done using `phpldapadmin` website as explained in [ivangfr/springboot-keycloak-openldap](https://github.com/ivangfr/springboot-keycloak-openldap#using-phpldapadmin-website)

## Configure Keycloak

- In a terminal, make sure you are in `springboot-keycloak-openldap` root folder

- Run the script below to configure `Keycloak` for `simple-service` application
  ```
  ./init-keycloak.sh "$(docker-machine ip manager1):8080"
  ```

  This script creates `company-services` realm, `simple-service` client, `USER` client role, `ldap` federation and the users `bgates` and `sjobs` with the role `USER` assigned.

- Copy `SIMPLE_SERVICE_CLIENT_SECRET` value that is shown at the end of the script. It will be needed whenever we call `Keycloak` to get a token to access `simple-service`

> **Note:** The `Keycloak` configuration can also be done using its website as explained in [ivangfr/springboot-keycloak-openldap](https://github.com/ivangfr/springboot-keycloak-openldap#using-keycloak-website)

## Test

1. Open a new terminal

1. Set `manager1` Docker Daemon
   ```
   eval $(docker-machine env manager1)
   ```

1. Run the following command to get the `manager` ip
   ```
   MANAGER1_IP=$(docker-machine ip manager1)
   ```

1. Call the endpoint `GET /api/public`
   ```
   curl -i http://$MANAGER1_IP:9080/api/public
   ```
   
   It should return
   ```
   HTTP/1.1 200
   It is public.
   ```

1. Try to call the endpoint `GET /api/private` without authentication
   ``` 
   curl -i http://$MANAGER1_IP:9080/api/private
   ```
   
   It should return
   ```
   HTTP/1.1 302
   ```
   > Here, the application is trying to redirect the request to an authentication link

1. Export the `Client Secret` generated by `Keycloak` to `simple-service` at [Configure Keycloak](#configure-keycloak) step
   ```
   export SIMPLE_SERVICE_CLIENT_SECRET=...
   ```
   
1. Run the following command to get a running Keycloak container
   ```
   KEYCLOAK_CONTAINER=$(docker ps --format {{.Names}} | grep keycloak)
   ```

1. Run the commands below to get an access token for `bgates` user
   ```
   BGATES_TOKEN=$(
     docker exec -t -e CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET $KEYCLOAK_CONTAINER bash -c '
       curl -s -X POST \
       http://keycloak:8080/auth/realms/company-services/protocol/openid-connect/token \
       -H "Content-Type: application/x-www-form-urlencoded" \
       -d "username=bgates" \
       -d "password=123" \
       -d "grant_type=password" \
       -d "client_secret=$CLIENT_SECRET" \
       -d "client_id=simple-service"')
   
   BGATES_ACCESS_TOKEN=$(echo $BGATES_TOKEN | jq -r .access_token)
   ```
   
   To check `BGATES_ACCESS_TOKEN` value run
   ```
   echo $BGATES_ACCESS_TOKEN
   ```

1. Call the endpoint `GET /api/private`
   ```
   curl -i -H "Authorization: Bearer $BGATES_ACCESS_TOKEN" http://$MANAGER1_IP:9080/api/private
   ```
   
   It should return
   ```
   HTTP/1.1 200
   bgates, it is private.
   ```
   
1. Get back to Host machine Docker Daemon
   ```
   eval $(docker-machine env -u)
   ```

## Shutdown

- In a terminal, make sure you are inside `docker-swarm-environment/simple-service-keycloak-ldap` folder

- Set `manager1` Docker Daemon
  ```
  eval $(docker-machine env manager1)
  ```

- Run the following scripts
  ```
  ./remove-app.sh && ./remove-infra-services.sh
  ```
  
- Get back to Host machine Docker Daemon
  ```
  eval $(docker-machine env -u)
  ```
