#!/bin/bash

if [ "${COVERAGE}" = "true" ]; then
  set -euv
  curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter;
  chmod +x ./cc-test-reporter;
fi
