#!/bin/bash
bundle exec rails assets:precompile
npx percy exec -- bundle exec rspec spec/features/percy/
