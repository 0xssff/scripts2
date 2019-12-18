#!/bin/sh

INSTALL_DISK="$1"
shift 1

CRYPTDISK='cryptroot'
TIMEZONE='Europe/London'
LOCALE='en_GB.UTF-8'
USERNAME='grufwub'

partition_disk() {
  # First lets wipe the drive
  dd if='/dev/urandom' of="$INSTALL_DISK" bs=1M status=progress

  printf "label: gpt
device: $INSTALL_DISK
unit: sectors

$INSTALL_DISK : start=        2048, size=      204800, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
$INSTALL_DISK : start=      206848, size=         max, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4\n" | sudo sfdisk "$INSTALL_DISK"
}

setup_cryptroot() {
  # Setup LUKS on second partition
  cryptsetup luksFormat "$INSTALL_DISK2" --type luks1 --cipher aes,xts,plain64 --hash sha512 --key-size 512 --use-random --iter-time 5000

  # Open LUKS
  cryptsetup luksOpen "$INSTALL_DISK2" "$CRYPTDISK"
}

setup_filesystems() {
  # First partition (efi)
  mkfs.vfat -F 32 "$INSTALL_DISK1"

  # cryptdisk (main partition)
  mkfs.btrfs "/dev/mapper/$CRYPTROOT"
  mkdir -p '/tmp/mnt'
  mount "/dev/mapper/$CRYPTROOT" '/tmp/mnt'
  btrfs subvolume create '/tmp/mnt/sv_root'
  btrfs subvolume create '/tmp/mnt/sv_home'
  btrfs subvolume create '/tmp/mnt/sv_var'
  btrfs subvolume create '/tmp/mnt/sv_var_log'
  btrfs subvolume create '/tmp/mnt/sv_usr'

  umount -R '/tmp/mnt'
}

btrfs_mount() {
  mount "/dev/mapper/$CRYPTDISK" "/mnt$1" -o "rw,relatime,compress=zstd:3,ssd,space_cache,subvolid=256,subvol=$2"
}

final_mount() {
  btrfs_mount 'sv_root' ''
  mkdir -p '/mnt/home'     && btrfs_mount 'sv_home'        '/home'
  mkdir -p '/mnt/var'      && btrfs_mount 'sv_var'         '/var'
  mkdir -p '/mnt/var/log'  && btrfs_mount 'sv_var_log'     '/var/log'
  mkdir -p '/mnt/usr'      && btrfs_mount 'sv_usr'         '/usr'

  mkdir -p '/mnt/boot/efi' && mount       "$INSTALL_DISK1" '/mnt/boot/efi'
}

pacstrap_install() {
  pacstrap '/mnt' base base-devel linux linux-firmware grub btrfs-progs dosfstools curl git
}

create_luks_keyfile() {
  dd if='/dev/random' of='/mnt/crypto_keyfile.bin' bs=1 count=4096 iflag=fullblock status=progress
  chmod 0 '/mnt/crypto_keyfile.bin'
  cryptsetup luksAddKey "$INSTALL_DISK2" '/mnt/crypto_keyfile.bin'
}

setup_base() {
  local disk_uuid grub_cmdline mkinitcpio_files mkinitcpio_hooks

  # Setup timezone, locale info
  ln -sf "/mnt/usr/share/zoneinfo/$TIMEZONE" '/mnt/etc/localtime'
  sed -i '/mnt/etc/locale.gen' -e "s|^#$LOCALE|$LOCALE|"
  echo "LANG=$LOCALE" >> '/mnt/etc/locale.conf'
  arch-chroot '/mnt' locale-gen

  # Get LUKS disk UUID
  disk_uuid=$(lsblk -o PATH,UUID | grep "$INSTALL_DISK2" | sed -e 's|.*\s||')
  
  # Setup filesystem mounting, automatic decryption etc
  genfstab -U >> '/mnt/etc/fstab'
  sed -i '/mnt/etc/fstab' -e "s|UUID=[^ ]*|/dev/mapper/$CRYPTDISK|g"
  printf "$CRYPTDISK\tUUID=$disk_uuid\t/crypto_keyfile.bin\tluks" >> '/mnt/etc/crypttab'

  # Setup GRUB cmdline
  grub_cmdline="cryptdevice=UUID=$disk_uuid:$CRYPTDISK intel_idle.max_cstate=1 cryptomgr.notests kvm-intel.nested=1 no_timer_check noreplace-smp intel_iommu=igfx_off page_alloc.shuffle=1 rootfstype=btrfs tsc=reliable modules.sig_enforce=1 apparmor=1 security=apparmor"
  sed -i '/mnt/etc/default/grub' -e 's|GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=""|'
  sed -i '/mnt/etc/default/grub' -e "s|GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"$grub_cmdline\"|"

  # Setup mkinitcpio + modprobe.d (i915, intel gpu)
  echo 'options i915 modeset=1 enable_fbc=1 enable_guc=2 enable_psr=1 disable_power_well=0' > '/mnt/etc/modprobe.d/i915.conf'

  mkinitcpio_files='/crypto_keyfile.bin /etc/modprobe.d/i915.conf /lib/firmware/i915/kbl_dmc_ver1_04.bin /lib/firmware/i915/kbl_guc_33.0.0.bin /lib/firmware/i915/kbl_huc_ver02_00_1810.bin'
  mkinitcpio_hooks='base udev autodetect modconf block encrypt usr filesystems keyboard fsck shutdown'
  sed -i '/mnt/etc/mkinitcpio.conf' -e "s|FILES=()|FILES=($mkinitcpio_files)|"
  sed -i '/mnt/etc/mkinitcpio.conf' -e "s|HOOKS=()|HOOKS=($mkinitcpio_hooks)|"
}

setup_boot() {
  arch-chroot '/mnt' mkinitcpio -p 'linux'
  arch-chroot '/mnt' grub-install --target=x86_64-efi --efi-directory=/boot/efi
  arch-chroot '/mnt' grub-mkconfig -o /boot/grub/grub.cfg
}

intall_extras() {
  arch-chroot '/mnt' pacman -S btrfs-progs dosfstools apparmor libvirt qemu virt-manager firewalld wget nano neovim xorg-server xorg-xinput xorg-xset xorg-xmodmap keychain networkmanager openvpn networkmanager-openvpn alsa-utils pulseaudio pulseaudio-alsa pavucontrol xfce4-settings xfce4-notifyd arc-gtk-theme macchanger xsecurelock
}

setup_extras() {
  arch-chroot '/mnt' systemctl enable NetworkManager
  arch-chroot '/mnt' systemctl enable apparmor
  arch-chroot '/mnt' systemctl enable firewalld

  # Setup firewalld to work correctly
  sed -i '/mnt/etc/firewalld/firewalld.conf' -e 's|FirewallBackend=.*|FirewallBackend=iptables|'
}

setup_user() {
  arch-chroot '/mnt' "useradd -m -g users -G wheel '$USERNAME'"
  arch-chroot '/mnt' "groupadd '$USERNAME'"
  arch-chroot '/mnt' "passwd '$USERNAME'"
  arch-chroot '/mnt' "passwd --lock root"
}

recurse_copy_files() {
  local fspath=$(echo "$1" | sed -e "s|^$2||")

  for f in $(ls -a "$1"); do
    [ "$f" = '.'  ] && continue
    [ "$f" = '..' ] && continue

    if [ -d "$1/$f" ]; then
      recurse_copy_files "$1/$f" "$2"
    else
      mkdir -p "$fspath"
      cp "$1/$f" "$fspath"
    fi
  done
}

grab_scripts_repo_contents() {
  local repopath='/tmp/git-scripts'

  # Need to enter /mnt for this...
  cd '/mnt'

  # Grab custom config files from github.com/grufwub/scripts
  git clone 'https://github.com/grufwub/scripts' "$repopath/tmp/git-scripts"
  recurse_copy_files "$repopath/fsroot"

  # Copy over dotfiles from cloned repository
  for f in $(ls -a "$repopath/dotfiles"); do
    cp "$repopath/dotfiles/$f" "/home/$USERNAME"
  done

  # Can back out of /mnt now
  cd ../

  # Copy scripts to userdir temporarily (sometimes /tmp gets cleared on arch-chroot)
  cp "/mnt$repopath/scripts/install_dwm.sh"      "/mnt/home/$USERNAME"
  cp "/mnt$repopath/scripts/install_ksh.sh"      "/mnt/home/$USERNAME"
  cp "/mnt$repopath/scripts/install_slstatus.sh" "/mnt/home/$USERNAME"

  # Install dwm, jupp and slstatus (easier to do by chroot)
  arch-chroot '/mnt' "su $USERNAME -c sh /home/$USERNAME/install_dwm.sh"
  arch-chroot '/mnt' "su $USERNAME -c sh /home/$USERNAME/install_ksh.sh"
  arch-chroot '/mnt' "su $USERNAME -c sh /home/$USERNAME/install_slstatus.sh"
}

set -e
partition_disk
setup_cryptroot
setup_filesystems
final_mount
pacstrap_install
create_luks_keyfile
setup_base
setup_boot
install_extras
setup_extras
setup_user
grab_scripts_repo_contents
set +e

# Time to finish up and reboot
umount -R '/mnt'
cryptsetup luksClose "$CRYPTDISK"
reboot