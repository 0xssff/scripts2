#!/bin/sh

INSTALL_DISK=''
CRYPTDISK='cryptroot'
TIMEZONE='Europe/London'
LOCALE='en_GB.UTF-8'

partition_disk() {

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
  mkinitcpio -p 'linux'
  grub-install --target=x86_64-efi --efi-directory=/boot/efi
  grub-mkconfig -o /boot/grub/grub.cfg
}

intall_extras() {
  pacman -S btrfs-progs dosfstools apparmor libvirt qemu virt-manager firewalld wget nano neovim xorg-server xorg-xinput xorg-xset xorg-xmodmap keychain networkmanager openvpn networkmanager-openvpn alsa-utils pulseaudio pulseaudio-alsa pavucontrol xfce4-settings xfce4-notifyd arc-gtk-theme macchanger
}

harden_install() {
  printf 'kernel.dmesg_restrict = 1\nkernel.kexec_loaded_disabled = 1\nnet.core.bpf_jit_harden = 2\n' > '/etc/sysctl.d/51-security.conf'
}

setup_extras() {
  systemctl enable NetworkManager
  systemctl enable apparmor
  systemctl enable firewalld

  # firewalld to iptables

  # macspoof systemd + enable
}

partition_disk
setup_cryptroot
setup_filesystems
final_mount
pacstrap_install
create_luks_keyfile
setup_base

# time to enter the filesystem
arch-chroot '/mnt'
setup_boot
install_extras
setup_extras

# time to exit chroot, unmount, reboot
exit
umount -R '/mnt'
cryptsetup luksClose "$CRYPTDISK"
reboot
