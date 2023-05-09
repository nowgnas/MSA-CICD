#!/bin/bash

# set variables
SERVICE=apigateway  
DIR=$(pwd)/server
REPO=S08P31A205
BRANCH=dev-be/apigateway
GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27

DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!
DOCKER_REPO=nowgnas/stockey:$SERVICE

DOCKER_COMPOSE_FILE=$DIR/apigateway.yml
GREEN_SERVICE_NAME=$SERVICE_green
BLUE_SERVICE_NAME=$SERVICE_blue

NETWORK=stockey-overlay

if [ ! -d $SERVICE ]; then
  mkdir $SERVICE
fi
cd $SERVICE
# check if git repo exists
if [ ! -d $REPO ]; then
  # git clone repo
  git clone -b ${BRANCH} https://${GITLAB_USERNAME}:${GITLAB_PASSWORD}@lab.ssafy.com/s08-final/${REPO}.git
  ls
  cd $REPO
else
  # git pull latest changes
  cd $REPO
  git pull
fi

echo "docker build"
# build new docker image
docker build -f server/apigateway-service/Dockerfile -t $DOCKER_REPO .

# push to docker hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push $DOCKER_REPO


# ------- push docker image to docker hub ---------

# Pulling the Docker image from Docker Hub
docker pull $DOCKER_REPO

# Deploying the Docker image using blue-green deployment strategy with Docker Swarm
# Assuming you have already initialized Docker Swarm and joined the necessary nodes

# Removing the green deployment if it already exists
docker service rm ${SERVICE}green

# Creating a Docker service with the blue deployment
docker service create \
  --name ${SERVICE}blue \
  --network $NETWORK \
  --env PROFILE=dev \
  --publish 8086:8000 \
  --detach \
  $DOCKER_REPO

# Waiting for the blue deployment to stabilize
echo "Waiting for the blue deployment to stabilize..."

sleep 30

# Creating a Docker service with the green deployment
docker service create \
  --name ${SERVICE}green \
  --network $NETWORK \
  --env PROFILE=dev \
  --publish 8087:8000 \
  --detach \
  $DOCKER_REPO

# Waiting for the green deployment to stabilize
echo "Waiting for the green deployment to stabilize..."
sleep 30

# Updating the routing mesh to route traffic to the green deployment
docker service update \
  --detach \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-order start-first \
  --update-monitor 30s \
  --update-max-failure-ratio 0.5 \
  --update-failure-action rollback \
  --env-add PROFILE=dev \
  ${SERVICE}blue

# Waiting for the routing mesh to update
echo "Waiting for the routing mesh to update..."
sleep 30

# Removing the blue deployment
docker service rm ${SERVICE}blue

echo "Blue-green deployment completed successfully!"
cd ..
sudo rm -rf ${REPO}
