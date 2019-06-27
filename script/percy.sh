#!/bin/bash
bundle exec rails assets:precompile
PERCY_TARGET_BRANCH=dev npx percy exec -- bundle exec rspec spec/features/
