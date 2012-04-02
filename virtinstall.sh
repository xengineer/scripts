#!/bin/bash

# --connect     : connection method to the hypervisor 
# --name=kvm001 : name of the host
# --ram=512     : amount of memories
# --vcpus=1     : amount of CPUs
# --disk=/usr/local/kvm_images/kvm001.img,size=8,format=raw,bus=virtio \
#               : which disk image to use
#               : size of an image
#               : format of an image(raw=raw disk format/qcow2=qemu format and slowest/vmdk=VMWare format)
#               : disk bus type of an image(ide/scsi/usb/virtio/xen)
# --cdrom='/home/hogehoge/work/os_iso/ubuntu-12.04-beta1-server-amd64.iso' \
#               : which CDROM image install
# --network=network:default,model=virtio,mac=12:78:34:91:56:01 \
#       network : how guestOS is connected to network(bridge/network/user)
#         model : guestOS' network driver(e1000/rtl8139/virtio)
#           mac : guestOS' MAC address
# --os-type=linux \
# --accelerate  : set this, and the installation goes quick.

virt-install \
--connect qemu:///system \
--name=kvm001 \
--ram=512 \
--vcpus=1 \
--disk=/usr/local/kvm_images/kvm001.img,size=8,format=raw,bus=virtio \
--cdrom='/home/nemoto_hideaki/work/os_iso/ubuntu-12.04-beta1-server-amd64.iso' \
--network=network:default,model=virtio,mac=12:78:34:91:56:01 \
--os-type=linux \
--accelerate 

