#!/bin/bash

# 모든 VM 중지 및 삭제
for vm in $(virsh list --all --name); do
    if [ -n "$vm" ]; then
        echo "Stopping and undefining VM: $vm"
        virsh destroy $vm
        virsh undefine $vm
    fi
done

# 기본 이미지 디렉토리의 이미지 파일 삭제
IMAGE_DIR="/var/lib/libvirt/images"
if [ -d "$IMAGE_DIR" ]; then
    echo "Deleting images in $IMAGE_DIR"
    sudo rm -f $IMAGE_DIR/*.qcow2 $IMAGE_DIR/*.img
else
    echo "Image directory $IMAGE_DIR does not exist"
fi

echo "All VMs and images have been deleted."
