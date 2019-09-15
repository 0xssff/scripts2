#!/bin/sh

PAGE='https://www.mirbsd.org/jupp.htm'
BASE_URL='http://www.mirbsd.org/MirOS/dist/jupp/'
VRSN_STR='joe-3.1jupp'
EXT='.tgz'
DOWNLOAD_FILE='jupp.tar.gz'
TAR_DIR='jupp'

C_FLAGS='-O2 -fno-delete-null-pointer-checks -fwrapv -fno-strict-aliasing'
PREFIX_DIR='/usr/local'
SYSCONF_DIR='/etc'
CONF_ARGS="--prefix=$PREFIX_DIR --sysconfdir=$SYSCONF_DIR --disable-dependency-tracking --disable-termidx" # --disable-getpwnam 

latest_version() {
  local vrsns latest_vrsn

  vrsns=$(curl -fL "$BASE_URL" --silent | grep -E 'joe-3\.1jupp[0-9]+.tgz</A>$' | sed -e 's|^<LI><A HREF=".*">||g' -e 's|</A>$||g' | sed -e "s|^$VRSN_STR||g" -e "s|$EXT$||g")

  latest_vrsn=$(printf "$vrsns\n" | head -n 1)
  for num in $vrsns; do
    [ $num -gt $latest_vrsn ] && latest_vrsn=$num
  done

  printf "$VRSN_STR$latest_vrsn$EXT\n"
}

latest_sha256() {
  curl -fL "$PAGE" --silent | grep "SHA256 ($1)" | sed -e 's|^.*= ||' -e 's|</li>$||'
}

bin_check() {
  silent() {
    $@ > /dev/null 2>&1
  }

  if ( ! silent $1 --version ) && ( ! silent $1 -v ) && ( ! silent $1 --help ) && ( ! silent $1 -h ); then
    printf "$1 not found!\n"
    return 1
  else
    return 0
  fi
}

initial_checks() {
  local result=0

  bin_check mktemp    || result=1
  bin_check curl      || result=1
  bin_check grep      || return=1
  bin_check sed       || return=1
  bin_check head      || return=1
  bin_check tar       || result=1
  bin_check sha256sum || result=1
  bin_check gcc       || result=1

  return $result
}

download() {
  local file_str url shasum latest_shasum

  # Find latest version
  file_str=$(latest_version)
  url="$BASE_URL$file_str"

  # Download latest .tar.gz
  printf "Downloading from $url\n"
  curl -fLo "$DOWNLOAD_FILE" "$url" --silent

  # Check download against latest version checksum
  latest_shasum=$(latest_sha256 "$file_str")
  shasum=$(sha256sum "$DOWNLOAD_FILE" | cut -d' ' -f1)

  if [ "$shasum" != "$latest_shasum" ]; then
    printf 'downloaded .tar.gz failed sha256 checksum!\n'
    return 1
  else
    printf 'successfully downloaded and verified jupp.tar.gz\n'
    return 0
  fi
}

compile() {
  # Unpack + enter directory
  tar -xzf "$DOWNLOAD_FILE"
  cd "$TAR_DIR"

  # Configure then make!
  CFLAGS=$C_FLAGS sh configure $CONF_ARGS || return 1
  make || return 1

  # Install!
  sudo make install || return 1

  return 0
}

main() {
  local orig_dir temp_dir

  # Perform initial checks
  initial_checks || return 1

  # Go to temporary directory
  orig_dir=$(pwd)
  temp_dir=$(mktemp -d)

  printf "Entering temp dir: $temp_dir\n"
  cd "$temp_dir"

  # Download jupp
  download || return 1

  # Compile jupp
  compile || return 1

  # Cleanup
  cd "$orig_dir"

  printf "Cleaning temp dir: $temp_dir\n"
  sudo rm -rf "$temp_dir"

  return 0
}

main
exit $?
