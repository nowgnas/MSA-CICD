#!/bin/bash

# set variables
DIR=$(pwd)
REPO=S08P31A205
BRANCH=dev-be/discovery
GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27
DOCKER_COMPOSE_BLUE_FILE=${DIR}/discovery.yml
DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!
DOCKER_REPO=nowgnas/stockey

DOCKER_COMPOSE_FILE=$DIR/discovery.yml
GREEN_SERVICE_NAME=discovery_green
BLUE_SERVICE_NAME=discovery_blue

# check if git repo exists
if [ ! -d ${REPO} ]; then
  # git clone repo
  git clone -b ${BRANCH} https://${GITLAB_USERNAME}:${GITLAB_PASSWORD}@lab.ssafy.com/s08-final/${REPO}.git
  cd ${REPO}
else
  # git pull latest changes
  cd ${REPO}
  git pull
  cd ..
fi

# build new docker image
docker build -f server/discovery-service/Dockerfile -t $DOCKER_REPO:latest .

# push to docker hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push $DOCKER_REPO:latest

# stop and remove the current blue service
docker-compose -f $DOCKER_COMPOSE_FILE stop $BLUE_SERVICE_NAME
docker-compose -f $DOCKER_COMPOSE_FILE rm -f $BLUE_SERVICE_NAME

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
