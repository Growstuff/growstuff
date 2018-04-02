#!/bin/bash
set -v

if [ "$(phantomjs --version)" != '2.1.1' ]; then
  PHANTOM_URL="https://assets.membergetmember.co/software/phantomjs-2.1.1-linux-x86_64.tar.bz2"
  rm -rf "$PWD/travis_phantomjs"
  mkdir -p "$PWD/travis_phantomjs"
  cd "$PWD/travis_phantomjs" || exit 1
  wget "$PHANTOM_URL"
  tar -vjxf phantomjs-2.1.1-linux-x86_64.tar.bz2
fi

which phantomjs
phantomjs --version
