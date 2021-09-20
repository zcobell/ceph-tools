#!/bin/bash

#...Ceph release to install
ceph_version="octopus"

#...Option to automatically configure all disks as OSDs
do_osd_configure=1

#...Single node server
single_node_cluster=1

#...Monitor ip
monip=10.211.55.10

#...Save intermediate crushmap files
save_crushmap_temporaries=0

#...Erasure code profile to create
k=2
m=1

#...Name of erasure pool to create
poolname=data_ec21

#...Filesystem to create
fsname=ceph-data

##############################
# End of config options
##############################

if [ "$EUID" != 0 ] ; then
    sudo "$0" "$@"
    exit $?
fi
