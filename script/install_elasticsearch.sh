#!/bin/bash

if [ "${GROWSTUFF_ELASTICSEARCH}" = "true" ]; then
  [[ -z "$VERSION" ]] && VERSION="6.2.3"
  set -euv
  sudo dpkg -r elasticsearch
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}.deb
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}.deb.sha512
  shasum -a 512 -c elasticsearch-${VERSION}.deb.sha512
  sudo dpkg -i --force-confnew elasticsearch-${VERSION}.deb

  sudo service elasticsearch start
  sleep 10
  curl -v localhost:9200
fi