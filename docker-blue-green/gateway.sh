#!/bin/bash

# set variables
SERVICE=apigateway

REPO=S08P31A205
BRANCH=dev-be/apigateway
GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27

DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!

GREEN_SERVICE_NAME=$SERVICE_green
BLUE_SERVICE_NAME=$SERVICE_blue

if [ ! -d $SERVICE ]; then
  mkdir $SERVICE
fi

echo "current dir: $(pwd)"
cd $SERVICE

# check if git repo exists
echo "current dir: $(pwd)"
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

echo "current dir: $(pwd)"

echo "docker build"
# build new docker image
docker build -f server/apigateway-service/Dockerfile -t nowgnas/stockey:$SERVICE .

# ------- push docker image to docker hub ---------

# Pushing the Docker image to Docker Hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push nowgnas/stockey:$SERVICE

# Deploying the Docker image using blue-green deployment strategy without Docker Swarm services

# Removing the green container if it already exists
docker rm -f $GREEN_SERVICE_NAME >/dev/null 2>&1

# Running the blue container
docker run --name $BLUE_SERVICE_NAME --network "stockey-overlay" -d -p 8086:8000 -e PROFILE=dev --network-alias $SERVICE nowgnas/stockey:$SERVICE

echo "Waiting for the blue deployment to stabilize..."
sleep 30

# Removing the blue container if it already exists
docker rm -f $BLUE_SERVICE_NAME >/dev/null 2>&1

# Running the green container
docker run --name $GREEN_SERVICE_NAME --network "stockey-overlay" -d -p 8087:8000 -e PROFILE=dev --network-alias $SERVICE nowgnas/stockey:$SERVICE

echo "Waiting for the green deployment to stabilize..."
sleep 30

# Removing the blue container
docker rm -f $BLUE_SERVICE_NAME >/dev/null 2>&1

echo "Blue-green deployment completed successfully!"
