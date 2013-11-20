#!/bin/bash
# Creates a container using an Ubuntu Cloud ISO and then
# imports into Docker. This will provide an image that
# is nearly identical to an Amazon (or Rackspace) Ubuntu AMI.
cd /tmp

DOCKER_USER=bradrydzewski
UBUNTU_RELEASE=precise
CONTAINER_NAME=ubuntu
CONTAINER_DIR=/var/lib/lxc/$CONTAINER_NAME/rootfs

# make sure container and image don't already exist
set +e
lxc-stop -n $CONTAINER_NAME
lxc-destroy -n $CONTAINER_NAME
docker rmi $DOCKER_USER/$CONTAINER_NAME
set -e

# create the default LXC container (takes ~10 minutes)
lxc-create -n $CONTAINER_NAME -t ubuntu-cloud -- -r $UBUNTU_RELEASE

# upstart workaround for docker
# see https://github.com/dotcloud/docker/issues/1024
chroot $CONTAINER_DIR dpkg-divert --local --rename --add /sbin/initctl
chroot $CONTAINER_DIR ln -s /bin/true /sbin/initctl

# override configurations
chroot $CONTAINER_DIR -- mkdir -p /home/ubuntu/.ssh && chown -R ubuntu:ubuntu .ssh
cat rootfs/etc/sudoers > $CONTAINER_DIR/etc/sudoers
cat rootfs/etc/init.d/xvfb > $CONTAINER_DIR/etc/init.d/xvfb
cat rootfs/etc/apt/apt.conf.d/90forceyes > $CONTAINER_DIR/etc/apt/apt.conf.d/90forceyes
cat rootfs/home/ubuntu/.bashrc > $CONTAINER_DIR/home/ubuntu/.bashrc
cat rootfs/home/ubuntu/.gitconfig > $CONTAINER_DIR/home/ubuntu/.gitconfig
cat rootfs/home/ubuntu/.ssh/config > $CONTAINER_DIR/home/ubuntu/.ssh/config

# install essential command binaries (scm, xserver)
chroot $CONTAINER_DIR -- apt-get -y install git git-core subversion mercurial bzr fossil xvfb

# tar the container
tar -czf $CONTAINER_NAME.tar -C $CONTAINER_DIR .

# import the container into docker
cat $CONTAINER_NAME.tar | docker import - $DOCKER_USER/$CONTAINER_NAME