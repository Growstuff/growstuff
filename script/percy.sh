#!/bin/bash
PERCY_TARGET_BRANCH=dev npx percy exec -- bundle exec rspec spec/features/percy/
