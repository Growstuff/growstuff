#!/bin/bash
bundle exec rails assets:precompile
export PERCY_TOKEN=047f5b0ecf3ca0a2bc94a6cfc837e625ace93ef0d81cc8ac82e3fb3aebd5c17f
PERCY_TARGET_BRANCH=dev npx percy exec -- bundle exec rspec spec/features/percy/
