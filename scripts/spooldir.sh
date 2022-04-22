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