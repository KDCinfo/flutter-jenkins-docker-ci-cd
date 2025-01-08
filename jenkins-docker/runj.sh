#!/bin/bash

printf "\n... ... ... begin\n"
# cd ~/Development/projects/src/dev-mac/jenkins-docker

### UPDATE HOST (MAC)
#
# The Mac (host) needs to be configured prior to starting up
# the Docker containers. This is done in another script file.

#
# Check socket permissions and owner.
printf "\nCheck for: [660 && root : docker] (on /Users/macuser/.docker/run/docker.sock)\n"
ls -la /Users/macuser/.docker/run/docker.sock
printf "\n"

#
# Read user input; set 'answer' to 'Y' if either Enter or Space is pressed (empty input)
read -n 1 -p "Has 'runmac.sh' been run? (Y/n) " answer
answer=${answer:-Y}  # If no input, default to 'Y'

#
# Check for 'y' or 'Y' (both should be treated the same)
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    printf "\nPlease run './runmac.sh' to update host.\n\n"
    exit 1
else
    printf "\n"
fi

### SCRIPT CONFIG
#
# @TODO: Replace this with your Jenkins install key
SECRET_KEY_FLUTTER_NODE="86c...x...y...z...62a"

CONTAINER_NAME_JENKINS="jenkins-docker"
CONTAINER_NAME_BLUEOCEAN="jenkins-blueocean"
CONTAINER_NAME_FLUTTER="flutter-node"

### PRE-CHECKS
#
# Check if jenkins-blueocean is running and if so, stop it.
printf "\n... ... ... checking if $CONTAINER_NAME_BLUEOCEAN is running...\n"
CONTAINER_ID=$(docker ps -q -f name=$CONTAINER_NAME_BLUEOCEAN)
# if [ $(docker ps -q -f name=$CONTAINER_NAME_BLUEOCEAN) ]; then
if [ -n "$CONTAINER_ID" ]; then
  printf "\n... Stopping $CONTAINER_NAME_BLUEOCEAN ...\n"
  docker stop -t 10 $CONTAINER_NAME_BLUEOCEAN
  printf "$CONTAINER_NAME_BLUEOCEAN stopped"
else
  printf "$CONTAINER_NAME_BLUEOCEAN is not running or does not exist"
fi

### START UP CONTAINERS
#
printf "\n\n... ... ... dind\n"
docker image pull docker:dind

printf "\n... ... ...jdk\n\n"
docker image pull jenkins/jenkins:lts
# docker image pull jenkins/jenkins:lts-jdk17

printf "\n... images pulled\n"

# Create a custom Docker network for Jenkins
NETWORK_NAME="jenkins"
if docker network ls | grep -q "$NETWORK_NAME"; then
  printf "\n... network '$NETWORK_NAME' already exists.\n"
else
  printf "\n... creating network '$NETWORK_NAME'.\n"
  docker network create jenkins
fi

# Run the Docker-in-Docker container
if docker ps --filter "name=$CONTAINER_NAME_JENKINS" | grep -q "$CONTAINER_NAME_JENKINS"; then
    printf "\n... container '$CONTAINER_NAME_JENKINS' is already running.\n"
else
    printf "\n... starting up container '$CONTAINER_NAME_JENKINS'.\n\n"
    docker run --name $CONTAINER_NAME_JENKINS --rm --detach \
      --privileged --network jenkins --network-alias docker \
      --env DOCKER_TLS_CERTDIR=/certs \
      --volume jenkins-docker-certs:/certs/client \
      --volume jenkins-data:/var/jenkins_home \
      --publish 2376:2376 \
      docker:dind --storage-driver overlay2
fi

# Build the custom Jenkins Docker image from Dockerfile
printf "\n... building myjenkins-blueocean (new images can take a few minutes)\n\n"
docker buildx build -f DockerfileController -t myjenkins-blueocean .

printf "\n... ... ... starting Jenkins Controller\n"

# Run or Start the Jenkins container with the custom image
if docker ps --filter "name=$CONTAINER_NAME_BLUEOCEAN" | grep -q "$CONTAINER_NAME_BLUEOCEAN"; then
    printf "\n... container '$CONTAINER_NAME_BLUEOCEAN' is already running.\n\n"
elif docker ps -a --filter "name=$CONTAINER_NAME_BLUEOCEAN" | grep -q "$CONTAINER_NAME_BLUEOCEAN"; then
    printf "\n... container '$CONTAINER_NAME_BLUEOCEAN' exists but is stopped. Starting it.\n\n"
    docker start $CONTAINER_NAME_BLUEOCEAN
else
    printf "\n... starting up container '$CONTAINER_NAME_BLUEOCEAN'.\n\n"
    # docker run --name $CONTAINER_NAME_BLUEOCEAN --restart=on-failure --detach \
    # docker run --name $CONTAINER_NAME_BLUEOCEAN --restart=no --detach \
    # docker run --name $CONTAINER_NAME_BLUEOCEAN --detach \
    docker run --name $CONTAINER_NAME_BLUEOCEAN --restart=unless-stopped --detach \
      --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
      --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
      --env JAVA_OPTS="-Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true" \
      --publish 8080:8080 --publish 50000:50000 \
      --volume jenkins-data:/var/jenkins_home \
      --volume jenkins-docker-certs:/certs/client:ro \
      myjenkins-blueocean
fi

printf "\n... ... ... starting Flutter agent node\n"

if docker ps --filter "name=$CONTAINER_NAME_FLUTTER" | grep -q "$CONTAINER_NAME_FLUTTER"; then
    printf "\n... container '$CONTAINER_NAME_FLUTTER' is already running.\n\n"
elif docker ps -a --filter "name=$CONTAINER_NAME_FLUTTER" | grep -q "$CONTAINER_NAME_FLUTTER"; then
    printf "\n... container '$CONTAINER_NAME_FLUTTER' exists but is stopped. Starting it.\n\n"
    docker start $CONTAINER_NAME_FLUTTER

    # @NOTE: This block is the same as in the 'else'.
    docker exec -it --user jenkins $CONTAINER_NAME_FLUTTER bash -c \
      "whoami && \
      groups jenkins && \
      ls -la /var/run/docker.sock && \
      sudo chmod 660 /var/run/docker.sock && \
      sudo chown root:docker /var/run/docker.sock && \
      ls -la /var/run/docker.sock"

    printf "\n\nTo double check ownership, run:\n"
    printf "\n> docker exec -it $CONTAINER_NAME_FLUTTER bash"
    printf "\n> ls -la /var/run/docker.sock"
    printf "\nIf not set to root:docker..."
    printf "\n> sudo chown root:docker /var/run/docker.sock\n"
else
    printf "\n... creating workspace directory.\n"
    JENKINS_WORKSPACE_PATH="/Users/macuser/Development/jenkins-workspace"
    mkdir -p $JENKINS_WORKSPACE_PATH && \
      chmod -R 775 $JENKINS_WORKSPACE_PATH
    #   chgrp -R docker /Users/macuser/Development/jenkins-workspace
    # RUN mkdir -p /home/developer/workspace && chown -R developer:developer /home/developer/workspace

    printf "\n... building agent image '$CONTAINER_NAME_FLUTTER'."
    # docker buildx build \
    #   -f DockerfileAgent \
    #   -t custom-jenkins-inbound-agent .
    #   --build-arg HOST_UID=$(id -u macuser) \
    #   --build-arg HOST_GID=$(id -g macuser) \
    docker buildx build \
      -f DockerfileAgent \
      -t custom-jenkins-inbound-agent .
    printf "\nJenkins agent has been built.\n"

    printf "\n\n... starting up container '$CONTAINER_NAME_FLUTTER'.\n\n"
    docker run --name $CONTAINER_NAME_FLUTTER --detach \
      --network jenkins \
      --env JENKINS_URL=http://$CONTAINER_NAME_BLUEOCEAN:8080/ \
      --env JENKINS_SECRET=$SECRET_KEY_FLUTTER_NODE \
      --env JENKINS_AGENT_NAME=flutter-node \
      --env JENKINS_LABELS=flutter \
      --volume /Users/macuser/Development/jenkins-workspace:/home/developer/workspace \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      custom-jenkins-inbound-agent
      # --user root \
      # --volume jenkins-agent-data:/home/developer/workspace \
      # --volume jenkins-agent-data:/home/jenkins \
      # --volume $(which docker):/usr/bin/docker \
      # --volume /var/run/docker.sock:/var/run/docker.sock \  # :ro ??
      #
      # jenkins/inbound-agent bash -c "usermod -aG docker jenkins && su jenkins"
      # jenkins/inbound-agent

    # docker.sock => Allow Docker to run in agent nodes.
    #
    printf "\n... [BEFORE].\n"
    docker exec -it --user jenkins $CONTAINER_NAME_FLUTTER bash -c \
      "whoami && \
      groups jenkins && \
      ls -la /var/run/docker.sock && \
      sudo chmod 660 /var/run/docker.sock && \
      sudo chown root:docker /var/run/docker.sock && \
      ls -la /var/run/docker.sock && \
      ls -la /home/developer/workspace"
    printf "\n... [AFTER].\n"

    printf "\nTo double check ownership, run:\n"
    printf "\n> docker exec -it $CONTAINER_NAME_FLUTTER bash"
    printf "\n> ls -la /var/run/docker.sock"
    printf "\nIf not set to root:docker..."
    printf "\n> sudo chown root:docker /var/run/docker.sock\n"
fi

printf "\nJenkins is starting up. You can access it at http://$CONTAINER_NAME_BLUEOCEAN:8080\n\n"
