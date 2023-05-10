#!/bin/bash

# set variables
SERVICE=laboratory
DIR=$(pwd)/server
REPO=S08P31A205
BRANCH=dev-be/laboratory
GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27

DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!
DOCKER_REPO=nowgnas/stockey:$SERVICE

DOCKER_COMPOSE_FILE=$DIR/laboratory.yml
GREEN_SERVICE_NAME=$SERVICE"-green"
BLUE_SERVICE_NAME=$SERVICE"-blue"

BACKPORT=8070
BLUEPORT=8088
GREENPORT=8089

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
docker build -f server/laboratory-service/Dockerfile -t $DOCKER_REPO .

# push to docker hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push $DOCKER_REPO


# ------- push docker image to docker hub ---------

# Pulling the Docker image from Docker Hub
docker pull $DOCKER_REPO

# Deploying the Docker image using blue-green deployment strategy with Docker Swarm
# Assuming you have already initialized Docker Swarm and joined the necessary nodes

# Removing the green deployment if it already exists
docker service rm $BLUE_SERVICE_NAME

# Creating a Docker service with the blue deployment
docker service create \
  --name $BLUE_SERVICE_NAME \
  --network $NETWORK \
  --env PROFILE=dev \
  --env ENCRYPT=stockey-key \
  --publish $BLUEPORT:$BACKPORT \
  --detach \
  $DOCKER_REPO

# Waiting for the blue deployment to stabilize
echo "Waiting for the blue deployment to stabilize..."
sleep 30

docker service rm $GREEN_SERVICE_NAME

# Creating a Docker service with the green deployment
docker service create \
  --name $GREEN_SERVICE_NAME \
  --network $NETWORK \
  --env PROFILE=dev \
  --env ENCRYPT=stockey-key \
  --publish $GREENPORT:$BACKPORT \
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
  --env-add ENCRYPT=stockey-key \
  $BLUE_SERVICE_NAME

# Waiting for the routing mesh to update
echo "Waiting for the routing mesh to update..."
sleep 30

echo "Blue-green deployment completed successfully!"
cd ..
sudo rm -rf $REPO
