#!/bin/bash
set -euv

if [ "${STATIC_CHECKS}" = "true" ]; then
  gem install --update overcommit rubocop haml-lint bundler-audit;
  npm install;
  pip install yamllint --user;

  overcommit --install;
  overcommit --sign;
  overcommit --sign pre-commit;

  bundle-audit update;
fi
