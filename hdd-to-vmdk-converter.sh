#!/bin/bash
# get a dd disk dump and convert it to vmware
#  see http://stackoverflow.com/questions/454899/how-to-convert-flat-raw-disk-image-to-vmdk-for-virtualbox-or-vmplayer
#  Author: wf  2014-10-1919

#
# get a dd dump from the given host's given disk and create a compressed
#   image at the given target
#
#  1: host e.g. somehost.somedomain
#  2: disk e.g. sda
#  3: target e.g. image.gz
#
getdump() {
  local l_disk="$1"
  local l_target="$2"
  echo "getting local disk dump of $l_disk from $l_disk"
  sudo dd if="${l_disk}" bs=1M | gzip -1 - | pv | dd of=$l_target
}

#
# optionally install command from package if it is not available yet
# 1: command
# 2: package
#
opt_install() {
  l_command="$1"
  l_package="$2"
  echo "checking that $l_command from package $l_package  is installed ..."
  which $l_command
  if [ $? -ne 0 ]
  then
    echo "installing $l_package to make $l_command available ..."
    sudo apt-get install $l_package
  fi
}

#
# convert the given image to vmware
#  1: the dd dump image
#  2: the vmware image file to convert to
#
vmware_convert() {
  local l_ddimage="$1"
  local l_vmwareimage="$2"
  echo "converting dd image $l_image to vmware $l_vmwareimage"
  #  convert to VMware disk format showing progess
  # see http://manpages.ubuntu.com/manpages/precise/man1/qemu-img.1.html
  qemu-img convert -p -O vmdk "$l_ddimage" "$l_vmwareimage"
}

#
# show usage
#
usage() {
  echo "usage: $0 host device"
  echo "      host: the host to get the disk dump from e.g. frodo.lotr.org"
  echo "            you need sudo privileges on that host"
  echo "
  echo "    device: the disk to dump from e.g. sda"
  echo ""
  echo "  examples:
  echo "       $0 frodo.lotr.org sda"
  echo "       $0 gandalf.lotr.org sdb"
  echo ""
  echo "  the needed packages pv and qemu-utils will be installed if not available"
  echo "  you need local sudo rights for this to work"
  exit 1
}

# check arguments
if [ $# -lt 1 ]
then
  usage
fi

# get the command line parameters
disk="$1"

# calculate the names of the image files
ts=`date "+%Y-%m-%d"`
# prefix of all images
#   .gz the zipped dd
#   .dd the disk dump file
#   .vmware - the vmware disk file
tmp_name=$(echo $1 | grep -Po '[^\/]*$')
image="./${tmp_name}.image_$ts"

echo "$0 $disk ->  $image"

# first check/install necessary packages
opt_install qemu-img qemu-utils
opt_install pv pv

# check if dd files was already loaded
#  we don't want to start this tedious process twice if avoidable
if [ ! -f $image.gz ]
then
  getdump $disk $image.gz
else
  echo "$image.gz already downloaded"
fi

# check if the dd file was already uncompressed
# we don't want to start this tedious process twice if avoidable
if [ ! -f $image.dd ]
then
  echo "uncompressing $image.gz"
  zcat $image.gz | pv -cN zcat > $image.dd
else
  echo "image $image.dd already uncompressed"
fi
# check if the vmdk file was already converted
# we don't want to start this tedious process twice if avoidable
if [ ! -f $image.vmdk ]
then
  vmware_convert $image.dd $image.vmdk
else
  echo "vmware image $image.vmdk already converted"
fi
