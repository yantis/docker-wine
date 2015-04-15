#!/bin/bash

############################################################
#         Copyright (c) 2015 Jonathan Yantis               #
#          Released under the MIT license                  #
############################################################
#                                                          #
#
# If you want to try this out just use this script to launch
# and connect on an AWS EC2 instance.
#
# IMPORTANT: make sure to change the userdefined variables
#
# You must have aws cli installed.
# https://github.com/aws/aws-cli
#
# If using Arch Linux it is on the AUR as aws-cli
#
# This uses just basic Amazon Linux for simplicity.
# Amazon Linux AMI 2015.03.0 x86_64 HVM 
#
# Usage:
# aws-skype.sh
#
############################################################


############################################################

# USER DEFINABLE (NOT OPTIONAL)
KEYNAME=yantisec2 # Private key name
SUBNETID=subnet-d260adb7 # VPC Subnet ID

# USER DEFINABLE (OPTIONAL)
REGION=us-west-2
IMAGEID=ami-e7527ed7

# Create our new instance
ID=$(aws ec2 run-instances \
  --image-id ${IMAGEID} \
  --key-name ${KEYNAME} \
  --instance-type t2.micro \
  --region ${REGION} \
  --subnet-id ${SUBNETID} | \
    grep InstanceId | awk -F\" '{print $4}')

# Sleep 10 seconds here. Just to give it time to be created.
sleep 10
echo "Instance ID: $ID"


# Query every second until we get our IP.
while [ 1 ]; do
  IP=$(aws ec2 describe-instances --instance-ids $ID | \
    grep PublicIpAddress | \
    awk -F\" '{print $4}')

  if [ -n "$IP" ]; then
    echo "IP Address: $IP"
    break
  fi

  sleep 1
done

# Sleep 30 seconds here. To give it even more time for the instance
# to get to a "running state" so we can attach the volume properly.
sleep 30

# Connect to the server and launch our container.
ssh -o ConnectionAttempts=255 \
    -o StrictHostKeyChecking=no \
    -i $HOME/.ssh/${KEYNAME}.pem\
    ec2-user@$IP -tt << EOF
  sudo yum update -y
  sudo yum install docker -y
  sudo service docker start
  sudo docker run \
    --privileged \
    -d \
    -v /home/ec2-user/.ssh/authorized_keys:/authorized_keys:ro \
    -p 49158:22 \
    yantis/wine
  exit
EOF

# Sleep 10 seconds here. To give it even more time for container 
sleep 10

# Now that is is launched go ahead and connect to our new server
ssh -Y \
    -o ConnectionAttempts=255 \
    -o StrictHostKeyChecking=no \
     root@$IP -p 49158 \
     -t sh /home/docker/templates/sqlyog.template

# This app has a habit of crashing the first time after install
# Go ahead and connect back a second time assuming it crashed out.
# Worst case the user gets to see this twice.
ssh -Y \
  -o ConnectionAttempts=255 \
  -o StrictHostKeyChecking=no \
  root@$IP -p 49158 \
  -t sh /home/docker/templates/sqlyog.template

# # Now that we are done. Delete the instance.
aws ec2 terminate-instances --instance-ids $ID
