#!/bin/bash

if [ "${STATIC_CHECKS}" = "true" ]; then
  set -euv
  yarn install;

  gem install --update overcommit haml-lint bundler-audit --no-document;

  # pip install --upgrade pip;
  pip install yamllint --user;

  overcommit --install;
  overcommit --sign;
  overcommit --sign pre-commit;

  bundle-audit update;
fi
