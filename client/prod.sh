#!/bin/bash

# set variables
SERVICE=client
REPO=S08P31A205
BRANCH=develop-fe
GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27

DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!
DOCKER_REPO=nowgnas/stockey:$SERVICE

NETWORK=stockey-overlay

if [ ! -d $SERVICE ]; then
  mkdir $SERVICE
fi
echo "currnet dir $(pwd)"
cd $SERVICE
# check if git repo exists
echo "currnet dir $(pwd)"
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
echo "currnet dir $(pwd)"

echo "docker build"
# build new docker image
docker build -f frontend/Dockerfile -t $DOCKER_REPO .

# push to docker hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push $DOCKER_REPO

docker rm -f client

docker run -d \
  --name client \
  --network $NETWORK \
  -p 3000:3000 \
  -p 80:80 \
  -p 443:443 \
  -v /etc/nginx:/etc/nginx \
  -v /etc/letsencrypt:/etc/letsencrypt \
  $DOCKER_REPO

cd ..
sudo rm -rf ${REPO}