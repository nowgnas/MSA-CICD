#!/bin/bash

# Set variables
SERVICE=client
REPO=S08P31A205
BRANCH=develop-fe

GITLAB_USERNAME=swlee0376
GITLAB_PASSWORD=BcQJVNsusbhbymaS3w27

DOCKER_HUB_USERNAME=nowgnas
DOCKER_HUB_PASSWORD=dltkddnjs!!
DOCKER_REPO=nowgnas/stockey:$SERVICE

NETWORK=stockey-overlay

# Clone or pull the repository
if [ ! -d "$REPO" ]; then
  # Clone the repository
  git clone -b "$BRANCH" "https://${GITLAB_USERNAME}:${GITLAB_PASSWORD}@lab.ssafy.com/s08-final/${REPO}.git"
  cd "$REPO"
else
  # Pull the latest changes
  cd "$REPO"
  git checkout "$BRANCH"
  git pull
fi

# Build the Docker image
docker build -f frontend/Dockerfile -t "$DOCKER_REPO" frontend/.

# Push to Docker Hub
echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
docker push "$DOCKER_REPO"

docker rm -f client

# Run the Docker container
docker run -d \
  --name client \
  --network "$NETWORK" \
  -p 3000:3000 \
  -p 80:80 \
  -p 443:443 \
  -v /path/to/nginx:/etc/nginx \
  -v /path/to/letsencrypt:/etc/letsencrypt \
  "$DOCKER_REPO"

# Clean up
cd ..
rm -rf "$REPO"
