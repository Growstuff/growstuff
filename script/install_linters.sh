#!/bin/bash

if [ "${STATIC_CHECKS}" = "true" ]; then
  set -euv

  rvm use 2.5.3; #overcommit doesn't support 2.6.0
  npm install;

  gem install --update overcommit haml-lint bundler-audit;
  gem install childprocess 0.7.0

  pip install --upgrade pip;
  pip install yamllint --user;

  overcommit --install;
  overcommit --sign;
  overcommit --sign pre-commit;

  bundle-audit update;
fi
