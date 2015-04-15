############################################################
# Copyright (c) 2015 Jonathan Yantis
# Released under the MIT license
############################################################
#
# ├─yantis/archlinux-tiny
#   ├─yantis/archlinux-small
#     ├─yantis/archlinux-small-ssh-hpn
#       ├─yantis/ssh-hpn-x
#         ├─yantis/dynamic-video
#           ├─yantis/virtualgl
#             ├─yantis/wine

FROM yantis/virtualgl
MAINTAINER Jonathan Yantis <yantis@yantis.net>

    # Update and force a refresh of all package lists even if they appear up to date.
RUN pacman -Syyu --noconfirm && \

    # Install Wine & Winetricks dependencies
    pacman --noconfirm -S \
    cabextract \
    lib32-gnutls \
    lib32-mpg123 \
    lib32-ncurses \
    p7zip \
    unzip \
    wine-mono \
    wine_gecko \
    wine && \

    # Install samba for ntlm_auth
    pacman --noconfirm -S samba --assume-installed python2 && \

    # Install Winetricks from github as it is more recent.
    curl -o winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    install -Dm755 winetricks /usr/bin/winetricks &&  \
    rm winetricks && \

    ##########################################################################
    # CLEAN UP SECTION - THIS GOES AT THE END                                #
    ##########################################################################
    localepurge && \

    # Remove info, man and docs
    rm -r /usr/share/info/* && \
    rm -r /usr/share/man/* && \
    rm -r /usr/share/doc/* && \

    # Delete any backup files like /etc/pacman.d/gnupg/pubring.gpg~
    find /. -name "*~" -type f -delete && \

    # Cleanup pacman
    bash -c "echo 'y' | pacman -Scc >/dev/null 2>&1" && \
    paccache -rk0 >/dev/null 2>&1 &&  \
    pacman-optimize && \
    rm -r /var/lib/pacman/sync/*

# Thow in some sample templates (bash scripts)
ADD examples/skype.template /home/docker/templates/skype.template
ADD examples/sqlyog.template /home/docker/templates/sqlyog.template

CMD /init
