#!/bin/bash

if [[ -z "$ELASTIC_SEARCH_VERSION" ]]; then
  echo "ELASTIC_SEARCH_VERSION variable not set"
else
  set -euv
  sudo dpkg -r elasticsearch
  wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb"
  wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512"
  shasum -a 512 -c "elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512"
  sudo dpkg -i --force-confnew "elasticsearch-${ELASTIC_SEARCH_VERSION}.deb"

  sudo service elasticsearch start
  sleep 10
  curl -v localhost:9200
fi
