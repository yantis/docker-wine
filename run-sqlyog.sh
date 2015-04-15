xhost +si:localuser:$(whoami) >/dev/null
docker run \
  --rm \
  -ti \
  -e DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -v ~/docker-data/wine:/home/docker/wine/ \
  -u docker \
  yantis/wine sh /home/docker/templates/sqlyog.template

# SQLyog doesn't need to initialize any graphics since it isn't using anything but 2D.

# Note make sure to create your  ~/docker-data/X
# directory beforehand or you might have permissions issues 
# if it gets auto created.

