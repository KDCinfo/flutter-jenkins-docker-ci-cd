#!/bin/bash

set -e

#
# This script is used to shell into the flutter-agent container for debugging.
#

# docker run -it \
#     --name flutter-agent \
#     --rm \
#     -u root:root \
#     -v /etc/passwd:/etc/passwd:ro \
#     -v /etc/group:/etc/group:ro \
#     -v /var/lib/jenkins/.ssh:/var/lib/jenkins-ssh:ro \
#     -v /Users/macuser/Development/jenkins-workspace:/home/developer/workspace \
#     -e LOCAL_USER="macuser" \
#     -e USER_DEVELOPER="developer" \
#     -e LOCAL_BIN="/usr/local/bin" \
#     -e PATH="/home/developer:/usr/local/bin:/usr/bin:/bin" \
#     -e USER_HOME="/home/developer" \
#     -e FLUTTER_HOME="/home/developer/flutter" \
#     -e WORKSPACE_HOME="/Users/macuser/Development/jenkins-workspace" \
#     -e WORKSPACE_LOCAL="/home/developer/workspace" \
#     macuser/local-dev-mac:latest

# docker run -it --name flutter-agent macuser/local-dev-mac:latest /bin/bash

CONTAINER_NAME="flutter-agent"
IMAGE_NAME="macuser/local-dev-mac:latest"

# Check if the container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    # If the container exists, check if it's stopped
    if [ "$(docker inspect -f '{{.State.Status}}' ${CONTAINER_NAME})" = "exited" ]; then
        echo "Container '${CONTAINER_NAME}' is stopped. Starting it..."
        docker start -i ${CONTAINER_NAME}
    else
        echo "Container '${CONTAINER_NAME}' is already running. Attaching to it..."
        docker exec -it ${CONTAINER_NAME} /bin/bash
    fi
else
    # If the container doesn't exist, create and run it
    echo "Container '${CONTAINER_NAME}' does not exist. Creating and running it..."
    docker run --rm -it --name ${CONTAINER_NAME} ${IMAGE_NAME} /bin/bash
fi
