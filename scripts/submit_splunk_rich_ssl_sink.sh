#!/bin/bash

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SPLUNKSINK_RICH_SSL",
  "config": {
    "confluent.topic.bootstrap.servers": "broker:29092",
    "name": "SPLUNKSINK_RICH_SSL",
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "topics": "RICH_SSL",
    "splunk.hec.token": "72ad3ec8-f73a-4db9-b052-1dad9cc63b31",
    "splunk.hec.uri": "https://splunk_search:8088",
    "splunk.hec.ssl.validate.certs": "false",
    "splunk.hec.json.event.formatted": "false"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors
