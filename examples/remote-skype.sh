#!/bin/bash

############################################################
#         Copyright (c) 2015 Jonathan Yantis               #
#          Released under the MIT license                  #
############################################################
#                                                          #
# Connect to remote SSH server and and launch our container
# then reconnect to that container and run VirtualGL over
# X-forwarding. Then shut down the container when done.
#
# Usage:
# remote-virtualgl.sh username hostname
#
# Example:
# remote-virtualgl.sh user hermes
#                                                          #
############################################################

# Exit the script if any statements returns a non true (0) value.
# set -e

# Exit the script on any uninitialized variables.
set -u

# Exit the script if the user didn't specify at least two arguments.
if [ "$#" -ne 2 ]; then
  echo "Error: You need to specifiy the user and host"
  exit 1
fi

USER_NAME=$2
HOST_NAME=$2

# Pick a random port as we might have multiple things running.
PORT=$[ 32767 + $[ RANDOM % 32767 ] ]

# Connect to the server and launch our container.
ssh -o StrictHostKeyChecking=no \
    $USER_NAME@$HOST_NAME -tt << EOF
sudo docker run \
  --privileged \
  -d \
  -h docker \
  -v /home/$USER_NAME/.ssh/authorized_keys:/authorized_keys:ro \
  -v ~/docker-data/wine:/home/docker/wine/ \
  -v /etc/localtime:/etc/localtime:ro \
  -p $PORT:22 \
  yantis/wine
  exit
EOF

# Now that is is launched go ahead and connect to our new server
vglconnect  -Y \
  -o ConnectionAttempts=255 \
  -o StrictHostKeyChecking=no \
  docker@$HOST_NAME -p $PORT  < skype.template

# Since we are done politely kill root to force a container shutdown.
ssh -o StrictHostKeyChecking=no \
  docker@$HOST_NAME -p $PORT \
  -t sudo pkill -INT -u root
