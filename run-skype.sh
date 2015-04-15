xhost +si:localuser:$(whoami) >/dev/null
docker run \
  --privileged \
  --rm \
  -ti \
  -e DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -v ~/docker-data/wine:/home/docker/wine/ \
  -v /etc/localtime:/etc/localtime:ro \
  -u docker \
  yantis/wine /bin/bash -c "sudo initialize-graphics >/dev/null 2>/dev/null; vglrun /home/docker/templates/skype.template;"

# Without virtualgl (Skype setup does not seem to work here)
# yantis/wine /bin/bash -c "sudo initialize-graphics >/dev/null 2>/dev/null; sh /home/docker/templates/skype.template;"

# With virtualgl
# yantis/wine /bin/bash -c "sudo initialize-graphics >/dev/null 2>/dev/null; vglrun /home/docker/templates/skype.template;"

# Note make sure to create your  ~/docker-data/X
# directory beforehand or you might have permissions issues 
# if it gets auto created.

