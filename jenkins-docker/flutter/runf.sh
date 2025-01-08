#!/bin/bash

# To run:
#
# > ./runf.sh
#   - No params: Build current version, do not push.
#
# > ./runf.sh push
#   - Param 1 is "push": Build current version, push.
#
# > ./runf.sh 1.0.0
#   - Param 1 is a version (pre-version), no second param: Build specified version, do not push.
#
# > ./runf.sh 1.0.0 push
#   - Param 1 is a version (pre-version), Param 2 is "push": Build specified version, push.
#
# > ./runf.sh 1.0
#   - Handle unexpected input gracefully.

# Exit on any error
set -e

# Default container name and version
CURRENT_VERSION="1.0.1"
DOCKER_HUB_USERNAME="macuser"
REPOSITORY_NAME="local-dev-mac"
# CONTAINER_NAME_FLUTTER="flutter-base-agent"
# CONTAINER_NAME_FLUTTER="macuser/local-dev-mac"

# 1.0.1 | Initial build

REPOSITORY_IMAGE="$DOCKER_HUB_USERNAME/$REPOSITORY_NAME"

# IMAGE_VERSION=${1:-"latest"}
# IMAGE_TAG=${1:-"latest"}
# IMAGE_TAG=${1:-$CURRENT_VERSION}
PUSH=false
IMAGE_TAG=""

if [ -z "$1" ]; then
    IMAGE_TAG=$CURRENT_VERSION
elif [ "$1" == "push" ]; then
    IMAGE_TAG=$CURRENT_VERSION
    PUSH=true
elif [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9])?$ ]]; then
    IMAGE_TAG=$1
    if [ "$2" == "push" ]; then
        PUSH=true
    fi
else
    # Case: Unexpected input
    printf "\n"
    echo "Usage:"
    echo "  No params: Build current version without pushing."
    echo "  'push': Build current version and push."
    echo "  '<version>': Build specified version without pushing."
    echo "  '<version> push': Build specified version and push."
    printf "\n"
    exit 1
fi

printf "... ... ... Starting Flutter node"

# Check for Docker Buildx
if ! docker buildx ls &> /dev/null; then
    printf "Error: Docker Buildx is not installed or enabled. Please install/enable Docker Buildx and try again."
    exit 1
fi

# Optional: Clean up unused images
printf "... Pruning images."
docker image prune -f

# Build the image with the specified tag
printf "... Building Flutter image '$REPOSITORY_IMAGE:$IMAGE_TAG'."
# docker buildx build -t $REPOSITORY_IMAGE:$IMAGE_TAG -f DockerfileFlutter .
docker buildx build -t $REPOSITORY_IMAGE:$IMAGE_TAG -t $REPOSITORY_IMAGE:latest -f DockerfileFlutter .

# Also tag version as latest.
# Scratch that... we'll do it in the 'buildx build' above instead.
# docker buildx build -t $REPOSITORY_IMAGE:latest -f DockerfileFlutter .
# docker tag $REPOSITORY_IMAGE:$IMAGE_TAG $REPOSITORY_IMAGE:latest

# Check for build success
if [ $? -ne 0 ]; then
    printf "Error: Docker image build failed. Exiting."
    exit 1
fi

printf "Docker image '$REPOSITORY_IMAGE:$IMAGE_TAG' has been built."

is_logged_in() {
    # Check if "auths" is a non-empty map
    if jq -e '.auths | length > 0' ~/.docker/config.json >/dev/null 2>&1; then
        return 0  # Logged in
    else
        return 1  # Not logged in
    fi
}

# - No params: Build current version, do not push.
# - Param 1 is "push": Build current version, push.
# - Param 1 is a version (pre-version), no second param: Build specified version, do not push.
# - Param 1 is a version (pre-version), Param 2 is "push": Build specified version, push.
# - Handle unexpected input gracefully.
#
# Optional: Push the image to Docker Hub.
if $PUSH; then
    # Login to Docker Hub (optional: skip if already logged in)
    printf "\n..."
    if ! is_logged_in; then
        printf "\nYou are not logged in to Docker Hub. Attempting login..."
        if ! docker login; then
            printf "\nDocker login failed. Exiting."
            exit 1
        fi
    else
        printf "\nAlready logged in to Docker Hub. Skipping login."
    fi

    # Push the versioned image
    printf "\nPushing image '$REPOSITORY_IMAGE:$IMAGE_TAG' to registry."
    printf "\n...\n"

    # We'll always push the param version or the current version.
    # If no version is passed in, current version is used.
    docker push $REPOSITORY_IMAGE:$IMAGE_TAG

    # Update 'latest' if param version is empty or is the current version.
    # 'latest' is not updated for previous versions, and future versions should
    #   not be passed; new versions should update the CURRENT_VERSION variable.
    # if [ "$IMAGE_TAG" != "latest" ]; then
    printf "\nIMAGE_TAG: '$IMAGE_TAG'"
    printf "\nCURRENT_VERSION: '$CURRENT_VERSION'"
    if [ "$IMAGE_TAG" == "$CURRENT_VERSION" ]; then
        printf "\nWe have equality!!\n...\n"
        docker push $REPOSITORY_IMAGE:latest
        printf "\n...\n"
    fi

    # Handling Deprecated or Experimental Tags
    # You might also want to add additional tags for specific use cases:
    # - experimental: For unstable or work-in-progress builds.
    # - deprecated: For older builds you no longer want to support but need available.
    # Example:
    # > docker tag $REPOSITORY_IMAGE:$VERSION $REPOSITORY_IMAGE:experimental
    # > docker push $REPOSITORY_IMAGE:experimental
    # https://chatgpt.com/g/g-9ZH8Jk74q-claude-3-5-sonnet/c/671c3569-3d5c-8009-8c90-7915ce7e7187
fi

# Using "tee"
#
# LOG_FILE="flutter_image_build.log"
#
# printf "\nLogging to $LOG_FILE\n"
# {
#     printf "\n... ... ... Starting Flutter node\n"
#     docker buildx build -t $REPOSITORY_IMAGE:$IMAGE_TAG -f DockerfileFlutter .
#     printf "\nDocker image '$REPOSITORY_IMAGE:$IMAGE_TAG' has been built.\n"
# } | tee $LOG_FILE

# OLD / INITIAL
#
# printf "\n... ... ... Starting Flutter node\n"
#
# CONTAINER_NAME_FLUTTER="flutter-base-agent"
#
# printf "\n... Building Flutter image '$CONTAINER_NAME_FLUTTER'."
# docker buildx build -t $CONTAINER_NAME_FLUTTER:latest -f DockerfileFlutter .
# printf "\nDocker image has been built.\n\n"
#
# printf "\n... starting up container '$CONTAINER_NAME_FLUTTER'.\n\n"
# docker run -it $CONTAINER_NAME_FLUTTER:latest /bin/bash
#
# printf "\n... [BEFORE].\n"
# docker exec -it --user jenkins $CONTAINER_NAME_FLUTTER bash -c \
#   "whoami"
# printf "\n... [AFTER].\n"
#
# printf "\nJenkins agent has started.\n\n"
