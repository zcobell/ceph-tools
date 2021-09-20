#!/bin/bash

#...Ceph release to install
ceph_version="octopus"

#...Option to automatically configure all disks as OSDs
do_osd_configure=1

#...Single node server
single_node_cluster=1

#...Monitor ip (automatically determined if single_node_cluster)
monip=192.168.0.1


if [ "$EUID" != 0 ] ; then
    sudo "$0" "$@"
    exit $?
fi

cd /root

#...Step 0: Gather Dependencies

# Docker 
echo "#---------------------------------#"
echo "# Step 0: Installing Dependencies #"
echo "#---------------------------------#"
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf update
dnf install docker-ce docker-ce-cli containerd.io -y
systemctl enable docker
systemctl start docker
dnf install chrony python3 lvm2 -y

hwclock --systohc
setenforce 0

echo "#---------------------------------#"
echo "# Step 1: Adding Ceph User        #"
echo "#---------------------------------#"
useradd -d /home/ceph -m ceph
echo "ceph ALL = (root) NOPASSWD:ALL" > /etc/sudoers.d/ceph
chmod 0440 /etc/sudoers.d/ceph


echo "#----------------------------------#"
echo "# Step 2: Downloading Cephadm Tool #"
echo "#----------------------------------#"
#...Downloads the latest version since it accounts for Rocky Linux
curl --silent --remote-name -location https://raw.githubusercontent.com/ceph/ceph/master/src/cephadm/cephadm
chmod +x cephadm


echo "#----------------------------------#"
echo "# Step 3: Installing Ceph: $ceph_version"
echo "#----------------------------------#"
./cephadm add-repo --release $ceph_version
./cephadm install


echo "#----------------------------------#"
echo "# Step 4: Set up the monitor       #"
echo "#----------------------------------#"
mkdir -p /etc/ceph
if [ $single_node_cluster == 1 ] ; then
    monip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | tail -n1)
fi
./cephadm bootstrap --mon-ip $monip 


echo "#----------------------------------#"
echo "# Step 5: Install ceph tools       #"
echo "#----------------------------------#"
./cephadm install ceph-common
./cephadm install ceph

if [ $do_osd_configure == 1 ] ; then
    ceph orch apply osd --all-available-devices
fi


