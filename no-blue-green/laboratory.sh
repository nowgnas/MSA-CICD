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

BACKPORT=8081
BLUEPORT=8086
GREENPORT=8083

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

docker rm -f $SERVICE

docker run -d \
  --name $SERVICE \
  --network $NETWORK \
  -e PROFILE=dev \
  -p $BLUEPORT:$BACKPORT \
  $DOCKER_REPO

echo "Blue-green deployment completed successfully!"
cd ..
sudo rm -rf $REPO
