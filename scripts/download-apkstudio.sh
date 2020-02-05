#!/bin/sh

print_exit() {
  printf '%s\n' "$2"
  exit $1
}

get_latest() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | sed -n -E 's|.*"tag_name": "([^"]+)",.*|\1|p'
}

download_apkstudio() {
  release=$(get_latest 'vaibhavpandeyvpz/apkstudio')
  url="https://github.com/vaibhavpandeyvpz/apkstudio/releases/download/$release/ApkStudio-$release-x86_64.AppImage"
  curl -fL "$url" -o 'ApkStudio.AppImage' || return 1
  chmod +x 'ApkStudio.AppImage'
}

download_apktool() {
  release=$(get_latest 'iBotPeaches/Apktool')
  url="https://github.com/iBotPeaches/Apktool/releases/download/$release/apktool_$(printf '%s' "$release" | sed -e 's|^v||').jar"
  curl -fL "$url" -o 'tools/apktool.jar' || return 1
}

download_jadx() {
  mkdir -p 'tools/jadx'
  release=$(get_latest 'skylot/jadx')
  url="https://github.com/skylot/jadx/releases/download/$release/jadx-$(printf '%s' "$release" | sed -e 's|^v||').zip"
  curl -fL "$url" -o 'tools/jadx/jadx.zip' || return 1
  unzip 'tools/jadx/jadx.zip' -d 'tools/jadx'
}

download_uberapksigner() {
  release=$(get_latest 'patrickfav/uber-apk-signer')
  url="https://github.com/patrickfav/uber-apk-signer/releases/download/$release/uber-apk-signer-$(printf '%s' "$release" | sed -e 's|^v||').jar"
  curl -fL "$url" -o 'tools/uber-apk-signer.jar' || return 1
}

main() {
  [ -d 'tools' ] && mv 'tools' 'tools.bak'
  [ -f 'ApkStudio.AppImage' ] && mv 'ApkStudio.AppImage' 'ApkStudio.AppImage.bak'

  printf 'Downloading latest ApkStudio AppImage:\n'
  download_apkstudio     || print_exit 1 'Failed to download apkstudio!'

  printf 'Creating tools subdirectory...\n'
  mkdir -p 'tools'

  printf 'Downloading latest apktool jar:\n'
  download_apktool       || print_exit 1 'Failed to download apktool!'

  printf 'Downloading latest jadx:\n'
  download_jadx          || print_exit 1 'Failed to download jadx!'

  printf 'Downloading latest uber-apk-signer jar:\n'
  download_uberapksigner || print_exit 1 'Failed to download uber-apk-signer!'
}

main
