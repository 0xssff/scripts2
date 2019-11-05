#!/bin/sh

function mount_filesystems() {
  sudo echo -n '' # just to ensure we still have sudo
  echo -n "Mounting filesystems..."
  if ( mount | grep "$1" > /dev/null 2>&1 ) ; then
    echo " Already mounted!"
  else
    sudo mount -t proc /proc "$1/proc"
    sudo mount -t sysfs /sys "$1/sys"
    sudo mount -o bind /dev "$1/dev"
    sudo mount -o bind /dev/pts "$1/dev/pts"
    echo " Done!"
  fi
}

function unmount_filesystems() {
  sudo echo -n '' # just to ensure we still have sudo
  echo -n "Unmounting filesystems..."
  if ( ps a | grep -e "sudo chroot $1 /bin/bash -c su.*--login$" > /dev/null 2>&1 ) ; then
    echo " User still logged in!"
  else
    sudo umount "$1/proc"
    sudo umount "$1/sys"
    sudo umount "$1/dev/pts"
    sudo umount "$1/dev"
    echo " Done!"
  fi
}

function enter_chroot()
{
  if ( ! sudo chroot "$1" echo -n '' ); then
    printf "'$1' is not a valid chroot!\n"
    return 1
  fi

  mount_filesystems "$1"
  sudo chroot "$1" /bin/bash -c "su $2 --login"
  unmount_filesystems "$1"
  return 0
}

if [ ! -d "$1" ]; then
  printf "Directory '$1' does not exist!\n"
  exit 1
fi

enter_chroot "$1" "$2"
exit $?