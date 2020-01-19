#!/bin/bash

if [[ -z "$ELASTIC_SEARCH_VERSION" ]]; then
  echo "ELASTIC_SEARCH_VERSION variable not set"
else
  echo "Downloading Elasticsearch ${ELASTIC_SEARCH_VERSION}"
  sudo dpkg -r elasticsearch


  wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb"
  wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512"

  shasum -a 512 -c "elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512"

  echo "Installing Elasticsearch ${ELASTIC_SEARCH_VERSION}"
  sudo dpkg -i --force-confnew "elasticsearch-${ELASTIC_SEARCH_VERSION}.deb"

  echo "Starting Elasticsearch ${ELASTIC_SEARCH_VERSION}"
  # sudo service elasticsearch start
  sudo systemctl start elasticsearch
fi
