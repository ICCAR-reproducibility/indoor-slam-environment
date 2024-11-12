# Use an Ubuntu 20.04 base image
FROM ubuntu:20.04

# Set up environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV GAZEBO_VERSION=11
ENV ROS_DISTRO=noetic

# Update packages and install dependencies
RUN apt-get update && \
    apt-get install -y \
    lsb-release \
    wget \
    gnupg2 \
    curl \
    tzdata && \
    echo "Etc/UTC" > /etc/timezone

# Add ROS and Gazebo package sources
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros-latest.list' && \
    wget -O - https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list' && \
    wget https://packages.osrfoundation.org/gazebo.key -O - | apt-key add -

# Install Gazebo, ROS Noetic, and the necessary ROS-Gazebo packages
RUN apt-get update && \
    apt-get install -y \
    ros-${ROS_DISTRO}-desktop-full \
    gazebo${GAZEBO_VERSION} \
    ros-${ROS_DISTRO}-gazebo-ros-pkgs \
    ros-${ROS_DISTRO}-gazebo-ros-control \
    ros-${ROS_DISTRO}-ros-ign && \
    apt-get clean

# Source ROS setup files
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

# Set up locale (required for some ROS/Gazebo features)
RUN apt-get update && \
    apt-get install -y locales && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Set up a user for running Gazebo (to avoid running as root)
RUN useradd -m gazebo_user && echo "gazebo_user:password" | chpasswd && adduser gazebo_user sudo
USER gazebo_user
WORKDIR /home/gazebo_user

# Copy your world file into the container
COPY --chown=gazebo_user:gazebo_user indoor_world_file/. /home/gazebo_user/worlds/

COPY --chown=gazebo_user:gazebo_user ./models/. /home/gazebo_user/.gazebo/models/

# Expose the necessary port for Gazebo (optional, if you need networking)
EXPOSE 11345

# Define default command to launch Gazebo with your world file
CMD ["bash", "-c", "source /opt/ros/${ROS_DISTRO}/setup.bash && gazebo /home/gazebo_user/worlds/small_warehouse.world"]

