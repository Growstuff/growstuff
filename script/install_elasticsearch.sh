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

  host="localhost:9200"
  # First wait for ES to start...
  response=$(curl $host)

  until [ "$response" = "200" ]; do
      response=$(curl -v  --write-out %{http_code} --silent --output /dev/null "$host")
      >&2 echo "Elastic Search is unavailable - sleeping.."
      sleep 1
  done


fi
