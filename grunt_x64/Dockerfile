ARG ROS_DISTRO=humble

# First stage: temporary build to modify configuration files
FROM osrf/ros:${ROS_DISTRO}-desktop-full-jammy as temp
ENV ROS_DISTRO=${ROS_DISTRO}

RUN apt-get -qq update && apt-get -qq --no-install-recommends install xrdp

# Copy the original configuration file to the temporary stage
RUN cp /etc/xrdp/xrdp.ini /tmp/xrdp.ini && \
    sed -i 's/3389/3389/g' /tmp/xrdp.ini && \
    echo 'display=:0' >> /tmp/xrdp.ini

RUN cp /tmp/xrdp.ini /tmp/xrdp_display2.ini && \
    sed -i 's/3389/3390/g' /tmp/xrdp_display2.ini && \
    echo 'display=:2' >> /tmp/xrdp_display2.ini

# Second stage: main build
FROM osrf/ros:${ROS_DISTRO}-desktop-full-jammy as base
ENV ROS_DISTRO=${ROS_DISTRO}
ENV TZ="America/Chicago"

SHELL ["/bin/bash", "-c"]

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install Git, dbus-x11, and other utilities
RUN apt-get -qq update && apt-get -y upgrade
RUN apt-get -qq --no-install-recommends install apt-utils git vim-gtk3 sudo less \
  inetutils-ping inetutils-traceroute net-tools xorg xserver-xorg-core x11-xserver-utils xvfb xfce4 xfce4-goodies xrdp openssh-server \
  xterm terminator python-is-python3 python3-pip software-properties-common dbus-x11

# Install needed ROS packages
RUN apt-get -qq --no-install-recommends install ros-${ROS_DISTRO}-swri-console ros-${ROS_DISTRO}-plotjuggler \
  ros-${ROS_DISTRO}-plotjuggler-ros python3-colcon-common-extensions ros-${ROS_DISTRO}-tf-transformations
RUN pip3 install transforms3d
RUN apt-get -qq --no-install-recommends install nano
RUN pip install setuptools==58.2.0

# Configure sudo
RUN ex +"%s/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/g" -scwq! /etc/sudoers

# Setup the default user
ARG CONFIGURED_USER=grunt
ARG CONFIGURED_PASSWD=Docker
ARG DISPLAY=:0
ENV DISPLAY=${DISPLAY}

# Create the group and user, ensuring the user is present, and add the user to the sudo group
RUN groupadd ${CONFIGURED_USER} && \
    useradd -ms /bin/bash -g ${CONFIGURED_USER} ${CONFIGURED_USER} && \
    echo "${CONFIGURED_USER}:${CONFIGURED_PASSWD}" | chpasswd && \
    adduser ${CONFIGURED_USER} sudo

# Create the .ssh directory and set permissions
RUN mkdir -p /home/${CONFIGURED_USER}/.ssh && \
    chown ${CONFIGURED_USER}:${CONFIGURED_USER} /home/${CONFIGURED_USER}/.ssh && \
    chmod 700 /home/${CONFIGURED_USER}/.ssh

# Copy the public keys into the .ssh directory
COPY config/pubkeys/*.pub /home/${CONFIGURED_USER}/.ssh/

# Concatenate all .pub files into authorized_keys and set correct permissions
RUN cat /home/${CONFIGURED_USER}/.ssh/*.pub > /home/${CONFIGURED_USER}/.ssh/authorized_keys && \
    rm /home/${CONFIGURED_USER}/.ssh/*.pub && \
    chown ${CONFIGURED_USER}:${CONFIGURED_USER} /home/${CONFIGURED_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${CONFIGURED_USER}/.ssh/authorized_keys

# Use ccache
ENV USE_CCACHE 1
ENV NDK_CCACHE /usr/bin/ccache
ENV CCACHE_DIR /opt/workspace/ccache
ENV PATH /usr/lib/ccache:$PATH

ENV QT_GRAPHICSSYSTEM native

# Add environment changes to .bashrc
COPY config/update_bashrc /sbin/update_bashrc
RUN chmod +x /sbin/update_bashrc && chown ${CONFIGURED_USER} /sbin/update_bashrc && sync && /bin/bash -c /sbin/update_bashrc && rm /sbin/update_bashrc

# Run rosdep update
RUN rosdep update

# Change entrypoint to source ~/.bashrc and start in ~
COPY config/entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh && chown ${CONFIGURED_USER} /ros_entrypoint.sh

# Copy modified configuration files from the temporary build stage
COPY --from=temp /tmp/xrdp.ini /etc/xrdp/xrdp.ini
COPY --from=temp /tmp/xrdp_display2.ini /etc/xrdp/xrdp_display2.ini

RUN echo 'startxfce4' > /home/${CONFIGURED_USER}/.xsession && \
    chown ${CONFIGURED_USER}:${CONFIGURED_USER} /home/${CONFIGURED_USER}/.xsession

# Configure SSH to run on port 2222
RUN cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak && \
    awk '/^#Port 22/ {print "Port 2222"; next} {print}' /etc/ssh/sshd_config.bak > /etc/ssh/sshd_config

# Set the working directory
WORKDIR /home/${CONFIGURED_USER}

# Set entrypoint
ENTRYPOINT ["/ros_entrypoint.sh"]
