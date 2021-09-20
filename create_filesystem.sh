#!/bin/bash

source config.sh

#...Create the base pool
ceph osd pool create ceph_metadata 64 64 replicated
ceph osd pool create ceph_data 64 64 replicated
ceph osd pool application enable ceph_metadata cephfs
ceph osd pool application enable ceph_data cephfs

#...Create an erasure coded pool
ceph osd pool create $poolname 64 64 erasure erasure_2_1
ceph osd pool application enable $poolname cephfs
ceph osd pool set $poolname allow_ec_overwrites true

#...Create the filesystem and apply an mds
ceph fs new $fsname ceph_metadata ceph_data
ceph fs add_data_pool $fsname $poolname
ceph orch apply mds $fsname --placement="1"

#...Mount the filesystem
cd /mnt
mkdir ceph-temp
mount -t ceph :/ /mnt/ceph-temp -o name=admin,secretfile=/etc/ceph/admin.secret
setfattr -n ceph.dir.layout.pool -v $poolname /mnt/ceph-temp 
getfattr -n ceph.dir.layout.pool /mnt/ceph-temp

#...Unmount the filesystem
umount /mnt/ceph-temp
rm -rf /mnt/ceph-temp
