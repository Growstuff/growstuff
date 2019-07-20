#!/bin/bash
set -euv
bundle exec rails assets:precompile
npx percy exec -- bundle exec rspec spec/features/percy/
