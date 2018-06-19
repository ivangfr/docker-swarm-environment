echo 
echo "Creating machines"
echo "-----------------"
docker-machine create --driver virtualbox manager1
# docker-machine create --driver virtualbox manager2
docker-machine create --driver virtualbox worker1
# docker-machine create --driver virtualbox worker2

echo 
echo "Starting swarm"
echo "--------------"
MANAGER1_IP=$(docker-machine ip manager1)

docker-machine ssh manager1 docker swarm init --advertise-addr $MANAGER1_IP

echo 
echo "Adding members"
echo "--------------"
MANAGER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet manager)
WORKER_TOKEN=$(docker-machine ssh manager1 docker swarm join-token --quiet worker)

# docker-machine ssh manager2 docker swarm join --token $MANAGER_TOKEN $MANAGER1_IP:2377
docker-machine ssh worker1 docker swarm join --token $WORKER_TOKEN $MANAGER1_IP:2377
# docker-machine ssh worker2 docker swarm join --token $WORKER_TOKEN $MANAGER1_IP:2377

echo 
echo "Creating overlay network"
echo "------------------------"
docker-machine ssh manager1 docker network create --driver overlay --attachable my-swarm-net