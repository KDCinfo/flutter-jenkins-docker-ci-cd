#!/bin/bash

printf "\n... ... ... begin [0]\n\n"

### UPDATE HOST (MAC)
#
ls -la /Users/macuser/.docker/run/docker.sock
printf "... ... ... before ^^^\n"

printf "\n... ... ... Need Mac/host local password for: 'chown' and 'chmod':\n"

sudo chown root:docker /Users/macuser/.docker/run/docker.sock
sudo chmod 660 /Users/macuser/.docker/run/docker.sock

printf "\n... ... ... after vvv\n"
ls -la /Users/macuser/.docker/run/docker.sock

printf "\n... ... ... Confirm: srw-rw----@ 1 root  docker\n\n"
