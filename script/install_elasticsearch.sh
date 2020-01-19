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

  if [[ $ELASTIC_SEARCH_VERSION == 7\.* ]]; then
    # https://stackoverflow.com/questions/55951531/running-elasticsearch-7-0-on-a-travis-xenial-build-host
    sudo sed -i.old 's/-Xms1g/-Xms128m/' /etc/elasticsearch/jvm.options
    sudo sed -i.old 's/-Xmx1g/-Xmx128m/' /etc/elasticsearch/jvm.options
    echo -e '-XX:+DisableExplicitGC\n-Djdk.io.permissionsUseCanonicalPath=true\n-Dlog4j.skipJansi=true\n-server\n' | sudo tee -a /etc/elasticsearch/jvm.options
    sudo chown -R elasticsearch:elasticsearch /etc/default/elasticsearch
  fi

  echo "Starting Elasticsearch ${ELASTIC_SEARCH_VERSION}"
  # sudo service elasticsearch start
  sudo systemctl start elasticsearch
fi
