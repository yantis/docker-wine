docker build -t yantis/wine .

docker run \
  --privileged \
  -ti \
  --rm \
  -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
  -p 49158:22 \
  -v ~/docker-data/wine:/home/docker/wine/ \
  yantis/wine

# Note make sure to create your  ~/docker-data/thunderbird
# directory beforehand or you might have permissions issues 
# if it gets auto created.

