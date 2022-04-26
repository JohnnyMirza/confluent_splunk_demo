#!/bin/bash
echo "Installing connector plugins"
confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest
confluent-hub install --no-prompt splunk/kafka-connect-splunk:latest
confluent-hub install --no-prompt confluentinc/kafka-connect-splunk-s2s:latest
confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:latest
#
echo "Launching Kafka Connect worker"
/etc/confluent/docker/run &
#
echo "waiting 2 minutes for things to stabilise"
sleep 120
echo "Starting the s2s conector"

  
HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "splunk-s2s-source",
  "config": {
    "connector.class": "io.confluent.connect.splunk.s2s.SplunkS2SSourceConnector",
    "topics": "splunk-s2s-events",
    "splunk.s2s.port":"9997",
    "kafka.topic":"splunk-s2s-events",
    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
    "value.converter":"org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable":"false",
    "value.converter.schemas.enable":"false",
    "confluent.topic.bootstrap.servers":"broker:29092",
    "confluent.topic.replication.factor":"1"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors

echo "Starting the Splunk Sink connector - HEC Formatted"

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SPLUNKSINK_HEC",
  "config": {
    "confluent.topic.bootstrap.servers": "broker:29092",
    "name": "SPLUNKSINK_HEC",
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "topics": "CISCO_ASA_FILTER_106023,PAN_THREAT",
    "splunk.hec.token": "3bca5f4c-1eff-4eee-9113-ea94c284478a",
    "splunk.hec.uri": "https://splunk_search:8088",
    "splunk.hec.ssl.validate.certs": "false",
    "splunk.hec.json.event.formatted": "true"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors


echo "Starting the Splunk Sink connector - HEC Formatted - Load Filtered Traffic"

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SPLUNKSINK_HEC_PAN_TRAFFIC",
  "config": {
    "confluent.topic.bootstrap.servers": "broker:29092",
    "name": "SPLUNKSINK_HEC_PAN_TRAFFIC",
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "topics": "PAN_TRAFFIC",
    "splunk.hec.token": "3bca5f4c-1eff-4eee-9113-ea94c284478a",
    "splunk.hec.uri": "https://splunk_search:8088",
    "splunk.hec.ssl.validate.certs": "false",
    "splunk.hec.json.event.formatted": "true"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors




echo "Starting the Splunk Sink connector - Raw"

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SPLUNKSINK_RAW",
  "config": {
    "confluent.topic.bootstrap.servers": "broker:29092",
    "name": "SPLUNKSINK_RAW",
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "topics": "AGGREGATOR",
    "splunk.hec.token": "3bca5f4c-1eff-4eee-9113-ea94c284478b",
    "splunk.hec.uri": "https://splunk_search:8088",
    "splunk.hec.ssl.validate.certs": "false",
    "splunk.hec.json.event.formatted": "false"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors


echo "Starting the Splunk CSVSpooldir Source connector"

HEADER="Content-Type: application/json"
DATA=$( cat << EOF
{
  "name": "SpoolDirCsvSourceConnector",
  "config": {
    "name": "SpoolDirCsvSourceConnector",
    "connector.class": "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
    "tasks.max": "1",
    "topic": "host_lookup",
    "key.schema": "{\n  \"name\" : \"hostlookup.Key\",\n  \"type\" : \"STRUCT\",\n  \"isOptional\" : false,\n  \"fieldSchemas\" : {\n    \"ip\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : false\n    }\n  }\n}",
    "value.schema": "{\n  \"name\" : \"hostlookup.Value\",\n  \"type\" : \"STRUCT\",\n  \"isOptional\" : false,\n  \"fieldSchemas\" : {\n    \"ip\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : false\n    },\n    \"hostname\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : false\n    },\n    \"domain\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : false\n    }\n  }\n}",
    "input.path": "/tmp/scripts/host_lookup",
    "finished.path": "/tmp/scripts/host_lookup/finished",
    "error.path": "/tmp/scripts/host_lookup/error",
    "input.file.pattern": "host_lookup.csv",
    "halt.on.error": "false",
    "csv.separator.char": "44",
    "csv.first.row.as.header": "true"

  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors


function wait_for_connector_to_be_configured () {
  sleep 3
  connector_name="SPLUNKSINK_HEC_PAN_TRAFFIC"
  datagen_tasks="1"
  prefix_cmd=""
  set +e
  # wait for all tasks to be FAILED with org.apache.kafka.connect.errors.ConnectException: Stopping connector: generated the configured xxx number of messages
  MAX_WAIT=3600
  CUR_WAIT=0
  $prefix_cmd curl -s -X GET http://localhost:8083/connectors/${connector_name}/status | jq .tasks[].state | grep "RUNNING" | wc -l > /tmp/out.txt 2>&1
  while [[ ! $(cat /tmp/out.txt) ]]; do
    sleep 5
    $prefix_cmd curl -s -X GET http://localhost:8083/connectors/${connector_name}/status | jq .tasks[].state | grep "RUNNING" | wc -l > /tmp/out.txt 2>&1
    CUR_WAIT=$(( CUR_WAIT+10 ))
    if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
      echo -e "\nERROR: Please troubleshoot'.\n"
      $prefix_cmd curl -s -X GET http://localhost:8083/connectors/${connector_name}/status | jq
      exit 1
    fi
  done
  curl -s -X PUT http://127.0.0.1:8083/connectors/SPLUNKSINK_HEC_PAN_TRAFFIC/pause

  set -e
}

wait_for_connector_to_be_configured


echo "Sleeping forever"
sleep infinity
