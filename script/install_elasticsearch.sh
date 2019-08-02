#!/bin/bash

if [ "${GROWSTUFF_ELASTICSEARCH}" = "true" ]; then
  [[ -z "$ELASTIC_SEARCH_VERSION" ]] && ELASTIC_SEARCH_VERSION="6.2.3"
  set -euv
  sudo dpkg -r elasticsearch
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512
  shasum -a 512 -c elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512
  sudo dpkg -i --force-confnew elasticsearch-${ELASTIC_SEARCH_VERSION}.deb

  sudo service elasticsearch start
  sleep 10
  curl -v localhost:9200
fi