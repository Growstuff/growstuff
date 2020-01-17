#!/bin/bash

if [[ -z "$ELASTIC_SEARCH_VERSION" ]]; then
  echo "ELASTIC_SEARCH_VERSION variable not set"
else
  sudo dpkg -r elasticsearch
  wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb"
  wget "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512"
  shasum -a 512 -c "elasticsearch-${ELASTIC_SEARCH_VERSION}.deb.sha512"
  sudo dpkg -i --force-confnew "elasticsearch-${ELASTIC_SEARCH_VERSION}.deb"

  echo "Telling Elasticsearch to start."
  sudo service elasticsearch start

  host="localhost:9200"
  response=""
  attempt=0

  until [ "$response" = "200" ]; do
      if [ $attempt -ge 25 ]; then
        echo "FAILED. Elasticsearch not responding after $attempt tries."
        tail /var/log/elasticsearch/*.log
        exit 1
      fi
      echo "Contacting Elasticsearch on ${host}. Try number ${attempt}"
      response=$(curl --write-out %{http_code} --silent --output /dev/null "$host")

      sleep 1
      attempt=$[$attempt+1]
  done
fi

echo "SUCCESS. Elasticsearch is responding."
