#!/bin/bash

if [[ -z "$ELASTIC_SEARCH_VERSION" ]]; then
  echo "ELASTIC_SEARCH_VERSION variable not set"
else
  host="localhost:9200"
  response=""
  attempt=0
  maxattempts=25

  # this would wait forever
  # until curl --silent -XGET --fail ${host} do printf '.'; sleep 1; done

  until [ "$response" = "200" ]; do
      if [ $attempt -ge ${maxattempts} ]; then
        echo "FAILED. Elasticsearch not responding after $attempt tries."
        sudo tail /var/log/elasticsearch/*.log
        exit 1
      fi
      echo "Contacting Elasticsearch on ${host}. Try number ${attempt}"
      response=$(curl --write-out %{http_code} --silent --output /dev/null $host)

      sleep 1
      attempt=$((attempt+1))
  done

  echo "SUCCESS. Elasticsearch is responding."
fi
