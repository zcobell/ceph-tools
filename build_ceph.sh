#!/bin/bash

source config.sh

cd /root

#...Step 0: Gather Dependencies

# Docker 
echo "#-------------------------------------#"
echo "# Step 0: Installing Dependencies     #"
echo "#-------------------------------------#"
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf update
dnf install docker-ce docker-ce-cli containerd.io -y --allowerasing
systemctl enable docker
systemctl start docker
dnf install chrony python3 lvm2 -y

hwclock --systohc
setenforce 0

echo "#-------------------------------------#"
echo "# Step 1: Adding Ceph User            #"
echo "#-------------------------------------#"
useradd -d /home/ceph -m ceph
echo "ceph ALL = (root) NOPASSWD:ALL" > /etc/sudoers.d/ceph
chmod 0440 /etc/sudoers.d/ceph


echo "#-------------------------------------#"
echo "# Step 2: Downloading Cephadm Tool    #"
echo "#-------------------------------------#"
#...Downloads the latest version since it accounts for Rocky Linux
curl --silent --remote-name -location https://raw.githubusercontent.com/ceph/ceph/master/src/cephadm/cephadm
chmod +x cephadm


echo "#-------------------------------------#"
echo "# Step 3: Installing Ceph: $ceph_version"
echo "#-------------------------------------#"
./cephadm add-repo --release $ceph_version
./cephadm install


echo "#-------------------------------------#"
echo "# Step 4: Set up the monitor          #"
echo "#-------------------------------------#"
mkdir -p /etc/ceph
./cephadm bootstrap --mon-ip $monip 


echo "#-------------------------------------#"
echo "# Step 5: Install ceph tools          #"
echo "#-------------------------------------#"
./cephadm install ceph-common
./cephadm install ceph

if [ $do_osd_configure == 1 ] ; then
    ceph orch apply osd --all-available-devices
fi

#...Generate the admin key file
ceph auth get-key client.admin > /etc/ceph/admin.secret

echo "#-------------------------------------#"
echo "# Step 6: Generating Erasure Profile  #"
echo "#-------------------------------------#"
#...Geneate an erasure coded 2-1 rule
if [ $single_node_cluster == 1 ] 
    ceph osd erasure-code-profile set "erasure_"$k"_"$m plugin=jerasure k=$k m=$m crush-failure-domain=osd
else
    ceph osd erasure-code-profile set "erasure_"$k"_"$m plugin=jerasure k=$k m=$m crush-failure-domain=host
fi
