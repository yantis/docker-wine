# docker-wine
[Wine](https://www.winehq.org/) on Docker with Dynamic Graphics drivers and VirtualGL with both local and remote support.

It should work out of the box with all Nvidia cards and Nvidia drivers and most other cards as well that use Mesa drivers.
It is setup to auto adapt to whatever drivers you may have installed as long as they are the most recent ones for your branch.

On Docker hub [wine](https://registry.hub.docker.com/u/yantis/wine/)
on Github [docker-wine](https://github.com/yantis/docker-wine/)


## Description
The goal of this was to be able to run windows apps on my Linux box from anywhere in the world but seamless as if it was a local application.
(That means no VNC or window managers etc). As an example maybe I want to run windows Skype on a remote server like an 
Amazon EC2 so my IP address doesn't get leaked to to anyone using a Skype IP resolver. There are also a few programs that
I like that just run on Windows.

In local mode it should just work out of the box. Though you do need to setup a shared folder as a volume to store your windows data.
All you should have to do is run [this](https://github.com/yantis/docker-wine/blob/master/runme-explorer.sh) script and it will launch
the windows explorer.

I have included a [demo script](https://github.com/yantis/docker-wine/blob/master/examples/aws-sqlyog.sh) 
that will start up an Amazon EC2 micro Instance, install docker, run the container and then connect to your docker container
and run SQLyog and outputting it on your local display.

[Here](https://github.com/yantis/docker-wine/blob/master/examples/remote-skype.sh) is another demo script 
that launches a Skype on another machine (ie: on your local network. To use that video card instead of your own)


### Docker Images Structure

>[yantis/archlinux-tiny](https://github.com/yantis/docker-archlinux-tiny)
>>[yantis/archlinux-small](https://github.com/yantis/docker-archlinux-small)
>>>[yantis/archlinux-small-ssh-hpn](https://github.com/yantis/docker-archlinux-ssh-hpn)
>>>>[yantis/ssh-hpn-x](https://github.com/yantis/docker-ssh-hpn-x)
>>>>>[yantis/dynamic-video](https://github.com/yantis/docker-dynamic-video)
>>>>>>[yantis/virtualgl](https://github.com/yantis/docker-virtualgl)
>>>>>>>[yantis/wine](https://github.com/yantis/docker-wine)


## Usage (Local)

This example launches the container and initializes the graphcs with your drivers and in this case
runs Skype for Windows (Actually, it runs a script that sets it up if it isn't installed or runs it if it is)

```bash
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
```

### Breakdown

```bash
$ xhost +si:localuser:yourusername
```

Allows your local user to access the xsocket. Change yourusername or use $(whoami) or $USER if your shell supports it.

```bash
docker run \
    --privileged \
    --rm \
    -ti \
    -e DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v ~/docker-data/wine:/home/docker/wine/ \
    -v /etc/localtime:/etc/localtime:ro \
    -u docker \
    yantis/wine /bin/bash -c "sudo initialize-graphics ; vglrun /home/docker/templates/skype.template;"
```

This follows these docker conventions:

* `-ti` will run an interactive session that can be terminated with CTRL+C.
* `--rm` will run a temporary session that will make sure to remove the container on exit.
* `-e DISPLAY` sets the host display to the local machines display.
* `-v /tmp/.X11-unix:/tmp/.X11-unix:ro` bind mounts the X11 socks on your local machine to the containers and makes it read only.
* `-v ~/docker-data/wine:/home/docker/wine/` shared volume (folder) for your Window's programs data.
* `-v /etc/localtime:/etc/localtime:ro \` sets the containers clock to match the hosts clock.
* `-u docker` sets the user to docker.
* 'yantis/wine /bin/bash -c "sudo initialize-graphics; vglrun /home/docker/templates/skype.template;"`
Initialize the correct video drivers and launch the built in Skype run or install script.
You could just as easily do any other program though.


## Usage (Remote)

### Server

The recommended way to run this container looks like this. This example launches the container in the background.
Warning: Do not run this on your primary computer as it will take over your video cards and you will have to shutdown the container
to get them back.

```bash
docker run \
    --privileged \
    -ti \
    --rm \
    -v $HOME/.ssh/authorized_keys:/authorized_keys:ro \
    -p 49158:22 \
    -v ~/docker-data/wine:/home/docker/wine/ \
    yantis/wine
```

This follows these docker conventions:

* `--privileged` run in privileged mode 
    If you do not want to run in privileged mode you can mess around with these:

    AWS
     * --device=/dev/nvidia0:/dev/nvidia0 \
     * --device=/dev/nvidiactl:/dev/nvidiactl \
     * --device=/dev/nvidia-uvm:/dev/nvidia-uvm \

    OR (Local)
     * --device=/dev/dri/card0:/dev/dri/card0 \

* `-d` run in daemon mode
* `-h docker` sets the hostname to docker. (not really required but it is nice to see where you are.)
* `-v $HOME/.ssh/authorized_keys:/authorized_keys:ro` Optionally share your public keys with the host.
    This is particularly useful when you are running this on another server that already has SSH. Like an 
    Amazon EC2 instance. WARNING: If you don't use this then it will just default to the user pass of docker/docker
    (If you do specify authorized keys it will disable all password logins to keep it secure).
* `-v /etc/localtime:/etc/localtime:ro` sets the containers clock to match the hosts clock.
* `-p 49158:22` port that you will be connecting to.
* `yantis/wine` the default mode is SSH server with the X-Server so no need to run any commands.


### Client

You will probably want to have VirtualGL installed on your client. Though this isn't mandatory for all apps.
ie: For 2D apps you will not need this but for apps like Skype and most games you will.

If you are just using 2D apps you can simply SSH in.

```bash
ssh -Y docker@hostname -p 49158 -t wine explorer.exe
```

If you are using 3D apps though you need to use VirtualGL.

On Arch Linux it is:

```bash
pacman -S virtualgl
```

It is basically two programs you need both of which I have included in the [tools](https://github.com/yantis/docker-virtualgl/tree/master/tools)
directory on my [docker-virtualgl](https://github.com/yantis/docker-virtualgl) repo

* SSH Authentication but data stream is unencrypted (recommended)

```bash
vglconnect -Y docker@hostname -p 49158 -t vglrun wine explorer.exe
```

* SSH Authentication AND data stream is unencrypted

```bash
vglconnect -Y -s docker@hostname -p 49158 -t vglrun wine explorer.exe
```

If you are running this remotely (ie: with an Amazon AWS server) You will want to open up port on your firewall
or router to get the best speed out of this.  Otherwise it will use SSH to encrypt the display which will slow it down a good amount.
(I have had varying degrees of success not opening the port when using the SSH method (Sometimes I have to open up the port period to get it to work.)

Check your ports as it doesn't always use 4242 sometimes it uses something else between 4200 and 4300.
If your screen is black or it isn't drawing then that is a good indication that the port is blocked.

![](http://yantis-scripts.s3.amazonaws.com/virtualgl_port_forwarding.png)

vglrun has a lot of tunable parameters. Make sure to check out the manual [here](http://www.virtualgl.org/vgldoc/2_1/)


## Examples

This is the latest version of Skype on Windows (The Windows version has a lot of features that the Linux ones doesn't have
like the ability to ability to set notifications based on keywords or ignore them completely for some groups).

I have included sample scripts to run this locally, over SSH (ie: on another computer on your LAN) as well as a script
to run it on an AWS micro instance if you are interested in protecting your privacy (it is very easy to query your IP
address via one of the many Skype IP resolver sites out there).

Skype actually needs 3D graphics support to work so we have to setup properly for that.

```
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
```

![](http://yantis-scripts.s3.amazonaws.com/skype_on_wine.png)


This is the latest version of [SQlyog](https://www.webyog.com/product/sqlyog). SQLyog doesn't need any 3D graphics so we can
skip initializing them. Also, it doesn't need privelged mode so no reason to give it that either.


```
xhost +si:localuser:$(whoami) >/dev/null
docker run \
    --rm \
    -ti \
    -e DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v ~/docker-data/wine:/home/docker/wine/ \
    -u docker \
    yantis/wine sh /home/docker/templates/sqlyog.template
```

![](http://yantis-scripts.s3.amazonaws.com/sqlyog_screenshot.png)
