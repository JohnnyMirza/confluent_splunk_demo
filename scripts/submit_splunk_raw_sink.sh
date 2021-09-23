#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SPLUNKSINK_COUNTS",
  "config": {
    "confluent.topic.bootstrap.servers": "broker:29092",
    "name": "SPLUNKSINK_COUNTS",
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "topics": "AGGREGATOR",
    "splunk.hec.token": "c4a03fd1-805e-4392-86cf-155ae87ad27e",
    "splunk.hec.uri": "https://splunk_search:8088",
    "splunk.hec.ssl.validate.certs": "false",
    "splunk.hec.json.event.formatted": "false"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors
