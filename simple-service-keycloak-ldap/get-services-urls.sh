#!/usr/bin/env bash

MANAGER1_IP=$(docker-machine ip manager1)

printf "\n"
printf "%15s | %42s | %34s |\n" "Service" "URL" "Credentials"
printf "%15s + %42s + %34s |\n" "---------------" "------------------------------------------" "----------------------------------"
printf "%15s | %42s | %34s |\n" "simple-service" "http://$MANAGER1_IP:9080/swagger-ui.html" ""
printf "%15s | %42s | %34s |\n" "keycloak" "http://$MANAGER1_IP:8080" "admin/admin"
printf "%15s | %42s | %34s |\n" "phpldapadmin" "https://$MANAGER1_IP:6443" "cn=admin,dc=mycompany,dc=com/admin"
printf "\n"
