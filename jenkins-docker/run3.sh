#!/bin/bash

printf "\n... ... ... begin\n"

# @TODO: Replace this with your Jenkins install key
SECRET_KEY_FLUTTER_NODE="86c...x...y...z...62a"

CONTAINER_NAME_BLUEOCEAN="jenkins-blueocean"
CONTAINER_NAME_FLUTTER="flutter-node"

printf "\n... ... ... starting Flutter agent node\n"

printf "\n... building agent image '$CONTAINER_NAME_FLUTTER'."
docker buildx build -f DockerfileAgent -t custom-jenkins-inbound-agent .
printf "\nJenkins agent has been built.\n\n"

printf "\n... starting up container '$CONTAINER_NAME_FLUTTER'.\n\n"
docker run --name $CONTAINER_NAME_FLUTTER --detach \
  --network jenkins \
  --env JENKINS_URL=http://$CONTAINER_NAME_BLUEOCEAN:8080/ \
  --env JENKINS_SECRET=$SECRET_KEY_FLUTTER_NODE \
  --env JENKINS_AGENT_NAME=flutter-node \
  --env JENKINS_LABELS=flutter \
  --volume /Users/macuser/Development/jenkins-workspace:/home/developer/workspace \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  custom-jenkins-inbound-agent
  # --volume jenkins-agent-data:/home/developer/workspace \
  # --volume jenkins-agent-data:/home/jenkins \
  # --volume $(which docker):/usr/bin/docker \
  # --volume /var/run/docker.sock:/var/run/docker.sock \  # :ro ??

printf "\n... [BEFORE].\n"
docker exec -it --user jenkins $CONTAINER_NAME_FLUTTER bash -c \
  "whoami && \
  groups jenkins && \
  ls -la /var/run/docker.sock && \
  sudo chmod 660 /var/run/docker.sock && \
  sudo chown root:docker /var/run/docker.sock && \
  ls -la /var/run/docker.sock && \
  ls -la /home/developer/workspace"
  # sudo chown -R jenkins:jenkins /home/developer && \
printf "\n... [AFTER].\n"

printf "\nJenkins agent has started.\n\n"
