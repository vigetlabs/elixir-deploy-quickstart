#!/bin/bash

# For the below to work, you will need to add your
# deploy user to not require a password for sudo.
# Below assumes 'deploy' is the user
# $ sudo visudo
#
# Then append to the end:
# deploy ALL=NOPASSWD: /bin/systemctl
# deploy ALL=NOPASSWD: /bin/journalctl
#
# If you skip this step, it will not restart the
# app on your server, but the rest should work.

PROD=204.48.29.223
SSH_USER=deploy
APP=your_app

# Don't accidently deploy for non-master branch
if [ "$(git symbolic-ref HEAD --short)" != "master" ]; then
  echo "You are not on the master branch and trying to deploy to production"
  echo "If you really want to deploy to production with a different branch"
  echo "you will need to do it manually"
  exit 1
fi

# Build the release
docker-compose -f builder.yml up --build

# Upload the release
read -rp 'Version: ' VERSION
echo "Uploading release"
scp _build/prod/rel/"$APP"/releases/"$VERSION"/"$APP".tar.gz "$SSH_USER"@"$PROD":~/"$APP"

# Backup, unpack, restart the app, and migrate if necessary
echo "Backing up and restarting the app on production"
ssh "$SSH_USER"@"$PROD" /bin/bash << EOF
  cd "$APP"
  pg_dump "$APP" > ./postgres_backups/$(date +%s).dump
  tar -xzf "$APP".tar.gz
  sudo systemctl restart "$APP"
  REPLACE_OS_VARS=true ./bin/"$APP" migrate
EOF
