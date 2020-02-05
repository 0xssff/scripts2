#!/bin/sh
#
# @grufwub
# PLATFORM: DESKTOP
#
# Though could be any platform really... Automates downloading and unpacking
# a large directory of apk files using apktool

print_exit() {
  printf '%s\n' "$2"
  exit $1
}

get_latest() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | sed -n -E 's|.*"tag_name": "([^"]+)",.*|\1|p'
}

download_apktool() {
  release=$(get_latest 'iBotPeaches/Apktool')
  url="https://github.com/iBotPeaches/Apktool/releases/download/$release/apktool_$(printf '%s' "$release" | sed -e 's|^v||').jar"
  curl -fL "$url" -o 'tools/apktool.jar' || return 1
}

main() {
  local filelist filename dirname

  [ -d 'tools' ] && mv 'tools' 'tools.bak'
  printf 'Creating tools subdirectory...\n'
  mkdir 'tools'

  printf 'Downloading latest apktool jar:\n'
  download_apktool || print_exit 1 'Failed to download apktool!'

  filelist=$(ls | sed -e 's| |#|g')
  for file in $filelist; do
    (echo "$file" | grep -qvE '\.apk$') && continue
    filename=$(echo "$file" | sed -e 's|#| |g')
    dirname=$(echo "$filename" | sed -e 's|\.apk$||')
    java -jar tools/apktool.jar decode "$filename" -o "$dirname"

    cd "$dirname"
    if [ -f 'assets/index.android.bundle' ]; then
      echo "$dirname" >> 'react_apps'
    fi
  done

  mkdir 'apk'
  mv *.apk apk/
}

main
