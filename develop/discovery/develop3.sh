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
fi

echo "docker build"
# build new docker image
docker build -f server/discovery-service/Dockerfile -t $DOCKER_REPO:latest .

# push to docker hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push $DOCKER_REPO:latest

echo "deploying stack"
# deploy stack with updated image
docker stack deploy --compose-file $DOCKER_COMPOSE_FILE --with-registry-auth --resolve-image always --prune $SERVICE

# confirm that blue-green deployment was successful
docker stack ps $SERVICE

rm -rf $REPO
