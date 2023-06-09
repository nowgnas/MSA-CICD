#!/bin/bash

# set variables
SERVICE=discovery
DIR=$(pwd)/server
REPO=S08P31A205
BRANCH=dev-be/discovery
GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27

DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!
DOCKER_REPO=nowgnas/stockey

DOCKER_COMPOSE_FILE=$DIR/discovery.yml
GREEN_SERVICE_NAME=$SERVICE_green
BLUE_SERVICE_NAME=$SERVICE_blue

if [ ! -d $SERVICE ]; then 
  mkdir $SERVICE
  cd $SERVICE
fi
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
  cd ..
fi

echo "docker build"
# build new docker image
docker build -f server/discovery-service/Dockerfile -t $DOCKER_REPO:latest .

# push to docker hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push $DOCKER_REPO:latest

echo "docker compose start"
# stop and remove the current blue service
docker-compose -f $DOCKER_COMPOSE_FILE stop $BLUE_SERVICE_NAME
docker-compose -f $DOCKER_COMPOSE_FILE rm -f $BLUE_SERVICE_NAME

echo "docekr stop rename up"
# rename green service to blue
docker-compose -f $DOCKER_COMPOSE_FILE stop $GREEN_SERVICE_NAME
docker-compose -f $DOCKER_COMPOSE_FILE rename $GREEN_SERVICE_NAME $BLUE_SERVICE_NAME
docker-compose -f $DOCKER_COMPOSE_FILE up -d $BLUE_SERVICE_NAME

# start new green service
docker-compose -f $DOCKER_COMPOSE_FILE up -d --scale $GREEN_SERVICE_NAME=1

# remove old images
docker image prune -f

# confirm that blue-green deployment was successful
docker-compose -f $DOCKER_COMPOSE_FILE ps

rm -rf $REPO