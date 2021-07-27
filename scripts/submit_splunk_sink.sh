#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SplunkSink",
  "config": {
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "topics": "splunk-s2s-events",
    "splunk.hec.uri":"https://splunk_search:8089",
    "splunk.hec.token":"3bca5f4c-1eff-4eee-9113-ea94c284478a",
    "value.converter":"org.apache.kafka.connect.storage.StringConverter",
    "confluent.topic.bootstrap.servers":"broker:29092",
    "splunk.hec.json.event.formatted": true,
    "tasks.max": "1"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors
