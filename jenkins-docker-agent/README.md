The README in the parent folder covers setting up the folder structure and cloning this repository.

This README covers everything else: setting and starting up Jenkins in Docker.

## Outline

- Routine Startup
- PART 1
  - Set up Jenkins: Pipelines, Nodes, and Credentials
- PART 2
  - `dev-mac/jenkins-docker`
    - `./runmac.sh  #` Run `chmod` on `docker.sock`
    - `./runj.sh  #  ` Start 3 Jenkins Docker containers
- PART 3
    - `dev-mac/jenkins-docker/flutter
    - `./runf.sh  #  ` Build Flutter environment
- PART 4
  - `dev-mac/jenkins-docker-agent
    - `./runa.sh  #  ` Run Mac Host Agent
- PART 5
  - Set up 'my-app'
- PART 6
  - Run through the flow


## Routine/Subsequent Startups

Once pipelines and nodes are created, and the 'agent.jar' is downloaded (see Part 4), the startup routine **after starting Docker Desktop** is always as follows:

```sh
> % cd Development/projects/src/dev-mac/jenkins-docker
> % ./runmac.sh
> % ./runj.sh  # 3 containers spin up
> % cd ../jenkins-docker-agent
> % ./runa.sh  # Agent stays running in terminal for observation
```

Other commands:

```sh
> % ./stopj.sh  # Stops all 3 Jenkins containers
```

Rare commands:

They should be, but I have not double checked that these are the same as what's in 'runj.sh' lately.

```sh
> % ./run2.sh  # Start up just the 'jenkins-blueocean' controller container
> % ./run3.sh  # Start up just the 'flutter-node' agent container
```


## PART 1: Set up Jenkins: Pipelines, Nodes, and Credentials

See the 'README-jenkins.md' file for instructions on creating the pipelines, as well as setting up nodes and creating credentials.


## PART 2:

Go through files and scripts and ensure there is nothing that stands out that needs changing.

> `% cd Development/projects/src/dev-mac/jenkins-docker`


## PART 3: Build Flutter Docker Image

This section should be done and run prior to the first Jenkins build, and for subsequent Flutter environment upgrades (although not the Flutter framework, for which the latest is always retrieved).

The files for this section are in the 'jenkins-docker\flutter' folder.

1. Update the 'runf.sh' file with your own Docker Hub info (i.e. `macuser`).
  - `DOCKER_HUB_USERNAME="macuser"`
2. Increase the current version in `runf.sh`.
  - `CURRENT_VERSION="1.0.1"`
3. Update the image file: `DockerfileFlutter`
4. Run the command that fits:
  - Any of these will build the image with the Flutter environment.
  - The final image can be stored in a private repo on Docker Hub.
  > CLI: ./runf.sh  # Build current version
  > CLI: ./runf.sh push  # Build and push current version
  > CLI: ./runf.sh 1.0.1  # Build a previous version (will replace latest)
  > CLI: ./runf.sh 1.0.0 push  # Build and push a previous version (will replace latest)


## PART 4: Set up Node for `jenkins-docker-agent`

The purpose of the `jenkins-docker-agent` is so iOS can build an IPA using the Mac host as the build environment, because IPAs cannot be built on Ubuntu.

There are alternatives for building the IPA, but using the Mac as a Jenkins agent was the most pragmatic solution in my case, already having the Mac host set up for Flutter development.

> **Note:** This jenkins-docker-agent should be started after Jenkins is started, prior to running an iOS build.

Side note: This script could be added to the tail end of `runj.sh` in the `jenkins-docker` sibling folder, but I didn't want to deal with subshells, and running this command in its own terminal also helps to keep it distinct from the other three primary Jenkins Docker containers.

### Initial MacOS Agent Setup

Once the Jenkins Pipelines and primary node and credentials have been configured, we can then create the Mac host agent.

Creation of the 'jenkins-workspace` folder is discussed in the root 'dev-mac' readme file.

> `% ls -la ~/Development/jenkins-workspace`
> drwxrwxr-x@ 8 macuser  docker   256 Jan  2 16:07 .

### In Jenkins

1. Visit: http://localhost:8080/manage/computer/new

```
  Name:            mac-host
  Type:            Permanent Agent

  Desc:            Local Mac for iOS builds.
  Remote root dir: /Users/macuser/Development/jenkins-workspace
  Labels:          [machost]
  Usage:           Only build jobs with label expressions matching this node
  Launch method:   Launch agent by connecting it to the controller
  Availability:    Keep this agent online as much as possible
```

**When you save**, it will show a page **with a secret**, and a way to save the secret to a file. It is recommended to save your secret as a 'secretfile' in your 'keys' path.

> `echo 3fe3....6072 > ../../keys/secretfile`
> #     ^^^ Secret     ^^^ Relative path from this readme
> cat ~/Development/projects/src/keys/secretfile

**Note:** A silent error was thrown when the 'secretfile' did not have a carriage return at the end. If creating the 'secretfile' from the command line, you may want to edit it and add an empty line.

### In a Terminal

2. Download the 'agent.jar' file.

> % cd ~/Development/projects/src/dev-mac/jenkins-docker-agent
> % curl -sO http://localhost:8080/jnlpJars/agent.jar

Once you save your secret in the `keys` folder, then run the `curl` command to download the 'agent.jar', running the `runa.sh` script will use those and be able to start up the agent node.

### Additional Jenkins Agent directions:

- https://www.jenkins.io/blog/2022/12/27/run-jenkins-agent-as-a-service/


## PART 5: Set up 'my-app'

- Refer to the 'README.md' in the '/my-app' directory for adding 'tools' and 'fastlane' folders.


## PART 6: Run Through the Flow

The following steps to view the Data Clump Flow JSON file are also outlined in the file:

- ~Development/projects/src/dev-mac/assets/dataclumpflow.txt

1. Visit: https://kdcinfo.com/app/dataflow
  - kdcinfo.com has been my personal domain for...ever!
  - The Data Flow Tool link is also available on https://kdcbase.com

2. [Optional] Create a new "Flow" storage space
  - Flow management is below the export/import buttons
  - Do not forget to "Use" the new Flow after creating it

3. Click the [Import Data] button

4. Select and load [dataclumps.json]


## Failures

@12/15/2024 1:02:24 AM
- CD | iOS
  - Mac
    > % cd Development/projects/flutter-apps/myapp/app
    > % flutter build ios --target=lib/app/app_bootstrap/main_prod.dart --flavor=production

    If that fails:

    - open ios/Runner.xcworkspace

    - Had to re-point Xcode in the Runner signing to my account.
    - Then had to agree to new "terms" in my Apple Developer account (in a browser).

    Then the signing was successful and it was able to build from the command line.
    I then opened Xcode and built to the iPad.


## Research

### Google: "docker" "dind" Install the Jenkins Agent on the Host Mac

To install a Jenkins agent on your Mac host using "Docker-in-Docker" (DinD), you need to set up a Docker container with the Jenkins agent software inside, while also enabling the container to access the host machine's Docker daemon by mounting the '/var/run/docker.sock' directory into the container, allowing it to run Docker commands within the containerized Jenkins agent environment.

Key steps:

- Install Docker on your Mac: Ensure you have Docker installed on your Mac system.
- Pull the "docker:dind" image: This image provides a Docker environment within a Docker container, essential for DinD functionality.
- Create a Dockerfile for your Jenkins agent:
  - Base image: Use the official Jenkins agent image as the base.
  - Mount Docker socket: Add a volume mount to map the host's Docker socket (/var/run/docker.sock) to the container's /var/run/docker.sock.
  - User permissions: Ensure the Jenkins agent user has appropriate permissions to access the Docker daemon within the container.

Important considerations:

- Security concerns: Be cautious when using DinD, as it allows a container to execute Docker commands on the host machine. Ensure proper user permissions and security practices are in place.
- Performance impact: Running Docker inside a Docker container can have performance implications depending on your hardware.


_
