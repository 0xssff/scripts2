#!/bin/sh

CUR_DIR=$(pwd)
SERV_NAME=''
GIT_URL=''
GIT_DIR="$HOME/git-public"
GIT_NAME=''
GIT_MAIL=''

# Ensure server git user setup
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_MAIL"

# Ensure git repo initialized
[ -d "$GIT_DIR" ] || git clone "$GIT_URL" "$GIT_DIR" || echo 'git clone failed'
cd "$GIT_DIR"

if ( ! git log ); then # repo empty
  git init
  git remote add "$GIT_URL"

  echo "$SERV_NAME public information repository" > README.md
  git add README.md
  git commit -m 'add readme' -s -v
  git push -u origin master
fi

# Dump domain blocks table then format
psql --dbname=mastodon_production -c "COPY (SELECT domain,severity from domain_blocks) TO stdout" > 'domain_blocks.txt'
sed -i 'domain_blocks.txt' -e 's|\s0$| [silenced]|g' -e 's|\s1$| [suspended]|g'

# Add domain blocks table
git add 'domain_blocks.txt'
git commit -m 'update domain_blocks.txt' -s -v
git push origin master

cd "$CUR_DIR"