#!/bin/bash

# Task 1: Clone GitLab repository with a specific branch
git clone -b <branch_name> <repository_url>

# Task 2: Build Docker image from backend server folder
cd <backend_server_folder>
docker build -t <image_name> .

# Task 3: Push built Docker image to Docker Hub
docker login -u <docker_username> -p <docker_password>
docker push <image_name>

# Task 4: Run Docker image from Docker Hub with blue-green deployment
docker pull <image_name>:latest

# Check if the blue deployment is running
if [ "$(docker ps -q -f name=<blue_container_name>)" ]; then
    # Blue deployment is already running, so create and start the green deployment
    docker run -d --name <green_container_name> -p <green_host_port>:<container_port> --network=host <image_name>:latest
    echo "Green deployment started."

    # Perform any necessary testing or validation on the green deployment

    # Stop and remove the blue deployment
    docker stop <blue_container_name>
    docker rm <blue_container_name>
    echo "Blue deployment stopped and removed."

    # Rename the green deployment as the new blue deployment
    docker rename <green_container_name> <blue_container_name>
    echo "Green deployment renamed as the new blue deployment."
else
    # Blue deployment is not running, so create and start the blue deployment
    docker run -d --name <blue_container_name> -p <blue_host_port>:<container_port> --network=host <image_name>:latest
    echo "Blue deployment started."
fi

# Task 5: Run Docker image (step 4) using Docker Swarm
docker swarm init --advertise-addr <swarm_manager_ip>
docker network create -d overlay --attachable stocky_overlay
docker service create --name <service_name> --network stocky_overlay --replicas 2 -p <host_port>:<container_port> <image_name>:latest
