ARG ROS_DISTRO=humble

FROM osrf/ros:${ROS_DISTRO}-desktop-full-jammy as base
ENV ROS_DISTRO=${ROS_DISTRO}
ENV TZ="America/Chicago"

SHELL ["/bin/bash", "-c"]

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install Git and other utilities from us.archive.ubuntu.com
RUN apt-get -qq update
RUN apt-get -y upgrade
RUN apt-get -qq --no-install-recommends install apt-utils
RUN apt-get -qq --no-install-recommends install git vim-gtk3 sudo less \
  && apt-get -qq --no-install-recommends install inetutils-ping inetutils-traceroute net-tools \
  && apt-get -qq --no-install-recommends install xorg xserver-xorg-core x11-xserver-utils xvfb xfce4 xfce4-goodies xrdp openssh-server  \
  && apt-get -qq --no-install-recommends install xterm terminator \
  && apt-get -qq --no-install-recommends install python-is-python3 \
  && apt-get -qq --no-install-recommends install python3-pip \
  && apt-get -qq --no-install-recommends install software-properties-common

# Install needed ROS packages
RUN apt-get -qq --no-install-recommends install ros-${ROS_DISTRO}-swri-console
RUN apt-get -qq --no-install-recommends install ros-${ROS_DISTRO}-plotjuggler
RUN apt-get -qq --no-install-recommends install ros-${ROS_DISTRO}-plotjuggler-ros
RUN apt-get -qq --no-install-recommends install python3-colcon-common-extensions
RUN apt-get -qq --no-install-recommends install ros-${ROS_DISTRO}-tf-transformations
RUN pip3 install transforms3d
RUN apt-get -qq --no-install-recommends install nano
RUN pip install setuptools==58.2.0

# Configure sudo.
RUN ex +"%s/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/g" -scwq! /etc/sudoers

# Setup the default user.

ARG CONFIGURED_USER=grunt
ARG CONFIGURED_PASSWD=Docker
ARG DISPLAY=:0
ENV DISPLAY=${DISPLAY}

# Create the group and user, ensuring the user is present, and add the user to the sudo group
RUN groupadd ${CONFIGURED_USER} && \
    useradd -ms /bin/bash -g ${CONFIGURED_USER} ${CONFIGURED_USER} && \
    adduser ${CONFIGURED_USER} sudo
#Setup the default user - grunt additions

# Copy the public keys into the container
COPY config/pubkeys/*.pub /home/${CONFIGURED_USER}/.ssh/authorized_keys

# Use ccache
ENV USE_CCACHE 1
ENV NDK_CCACHE /usr/bin/ccache
ENV CCACHE_DIR /opt/workspace/ccache
ENV PATH /usr/lib/ccache:$PATH

ENV QT_GRAPHICSSYSTEM native

# add environment changes to .bashrc
WORKDIR /home/${CONFIGURED_USER}
USER ${CONFIGURED_USER}
COPY config/update_bashrc /sbin/update_bashrc
RUN sudo chmod +x /sbin/update_bashrc ; sudo chown ${CONFIGURED_USER} /sbin/update_bashrc ; sync ; /bin/bash -c /sbin/update_bashrc ; sudo rm /sbin/update_bashrc

# run rosdep update
RUN rosdep update

# Change entrypoint to source ~/.bashrc and start in ~
COPY config/entrypoint.sh /ros_entrypoint.sh
RUN sudo chmod +x /ros_entrypoint.sh ; sudo chown ${CONFIGURED_USER} /ros_entrypoint.sh ;

# startup environment
WORKDIR /home/${CONFIGURED_USER}
ENTRYPOINT ["/ros_entrypoint.sh"]

# Set the correct permissions for the SSH directory and authorized_keys file
RUN sudo chown -R ${CONFIGURED_USER}:${CONFIGURED_USER} /home/${CONFIGURED_USER}/.ssh && \
    chmod 700 /home/${CONFIGURED_USER}/.ssh && \
    chmod 600 /home/${CONFIGURED_USER}/.ssh/authorized_keys

# Set up XRDP configuration
RUN sudo sed -i 's/3389/3388/g' /etc/xrdp/xrdp.ini && \
    echo 'display=:0' >> /etc/xrdp/xrdp.ini && \
    echo 'startxfce4' > /home/${CONFIGURED_USER}/.xsession && \
    chown ${CONFIGURED_USER}:${CONFIGURED_USER} /home/${CONFIGURED_USER}/.xsession

# Copy XRDP configuration for the second virtual display
RUN sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp_display2.ini && \
    sed -i 's/3388/3389/g' /etc/xrdp/xrdp_display2.ini && \
    echo 'display=:2' >> /etc/xrdp/xrdp_display2.ini

# Configure SSH to run on port 2222
RUN sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Expose the XRDP and SSH ports
EXPOSE 3388 3389 2222

# Start the necessary services and the virtual display
CMD service ssh start && \
    startxfce4 & \
    Xvfb :2 -screen 0 1920x1080x16 & \
    export DISPLAY=:2 && startxfce4 & \
    service xrdp start && \
    service xrdp start --config /etc/xrdp/xrdp_display2.ini && \
    tail -f /dev/null