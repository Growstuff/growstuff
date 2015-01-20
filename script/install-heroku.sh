#!/bin/sh
# Install the Heroku toolbelt
wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh

if [ "$TRAVIS_BRANCH" = "dev" ]; then
        APP_NAME=growstuff-staging
elif [ "$TRAVIS_BRANCH" = "master" ]; then
        APP_NAME=growstuff-prod
elif [ "$TRAVIS_BRANCH" = "travis_deploy" ]; then
        APP_NAME=tranquil-basin-3130
else
        echo "Couldn't find app corresponding to branch $TRAVIS_BRANCH"
        exit 1
fi

git remote add heroku git@heroku.com:$APP_NAME.git
echo >> ~/.ssh_config <<END_SSH_CONFIG
Host heroku.com
  StrictHostKeyChecking no
  CheckHostIP no
  UserKnownHostsFile=/dev/null
END_SSH_CONFIG

yes | heroku keys:add
