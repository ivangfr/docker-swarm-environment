#!/usr/bin/env bash

MANAGER1_IP=$(docker-machine ip manager1)

printf "\n"
printf "%15s | %42s |\n" "Service" "URL"
printf "%15s + %42s |\n" "---------------" "------------------------------------------"
printf "%15s | %42s |\n" "producer-api" "http://$MANAGER1_IP:9080/swagger-ui.html"
printf "%15s | %42s |\n" "publisher-api" "http://$MANAGER1_IP:9083/swagger-ui.html"
printf "%15s | %42s |\n" "news-client" "http://$MANAGER1_IP:8080"
printf "%15s | %42s |\n" "eureka" "http://$MANAGER1_IP:8761"
printf "%15s | %42s |\n" "zipkin" "http://$MANAGER1_IP:9411"
printf "%15s | %42s |\n" "elasticsearch" "http://$MANAGER1_IP:9200"
printf "%15s | %42s |\n" "schema-registry" "http://$MANAGER1_IP:8081"
printf "\n"
