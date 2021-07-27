Streaming data from Splunk to Kafka using KSQLDB for filtering, while keeping all the Splunk MetaData (source,sourcetype,host,event) <jmirza@confluent.io>
v1.00, 3 November 2020

TL;DR
```
QuickStart
1. git clone https://github.com/JohnnyMirza/splunk_forward_to_kafka.git
2. docker-compose up -d
3. Configure Splunk UF’s to send to the above instance
```

![image](splunk_forward_to_kafka.png)

This app is a set custom inputs/transforms that allows you to send "under-cooked" data to apache kafka. Spin up using Docker-Compose and just forward your UFs to the instance. 


Getting started 

1. Bring the Docker Compose up

[source,bash]
```
docker-compose up -d
```

2. Make sure everything is up and running

[source,bash]
```
#docker-compose ps
```
```     Name                    Command                  State                    Ports
broker            /etc/confluent/docker/run        Up             0.0.0.0:9092->9092/tcp
control-center    /etc/confluent/docker/run        Up             0.0.0.0:9021->9021/tcp
elasticsearch     /tini -- /usr/local/bin/do ...   Up             0.0.0.0:9200->9200/tcp, 9300/tcp
kafka-connect     bash -c echo "Installing c ...   Up (healthy)   0.0.0.0:5555->5555/tcp, 0.0.0.0:8083->8083/tcp, 9092/tcp
kibana            /usr/local/bin/dumb-init - ...   Up             0.0.0.0:5601->5601/tcp
ksqldb            /etc/confluent/docker/run        Up             0.0.0.0:8088->8088/tcp
schema-registry   /etc/confluent/docker/run        Up             0.0.0.0:8081->8081/tcp
splunk_hf         /sbin/entrypoint.sh start- ...   Up (healthy)   0.0.0.0:8001->8000/tcp, 8065/tcp, 8088/tcp, 8089/tcp,
                                                                  8191/tcp, 9887/tcp, 0.0.0.0:9997->9997/tcp
splunk_search     /sbin/entrypoint.sh start- ...   Up (healthy)   0.0.0.0:8000->8000/tcp, 8065/tcp, 8088/tcp, 8089/tcp,
                                                                  8191/tcp, 9887/tcp, 0.0.0.0:9998->9997/tcp
zookeeper         /etc/confluent/docker/run        Up             2181/tcp, 2888/tcp, 3888/tcp
```

The rest of the work will be done through Confluent Control Center, login by going to http://localhost:9021 and go to the KSQLDB Editor to run the below commands

1. Create syslog connector source to listen to TCP5555, this is where the Splunk HF is configured to send the under-cooked data
[source,sql]

```
CREATE SOURCE CONNECTOR SYSLOG_TCP WITH (
  'connector.class' =  'io.confluent.connect.syslog.SyslogSourceConnector',
  'kafka.topic' =  'splunk-syslog-tcp',
  'confluent.topic.bootstrap.servers' =  'broker:29092',
  'topic' = 'splunk-syslog-tcp',
  'producer.interceptor.classes' =  'io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor',
  'value.converter' =  'org.apache.kafka.connect.json.JsonConverter',
  'value.converter.schemas.enable' =  'false',
  'syslog.listener' =  'TCP',
  'syslog.port' =  '5555',
  'tasks.max' =  '1'
);
```

2. Create Splunk Streams to extracted the undercooked data
[source,sql]

```
CREATE STREAM SPLUNK (
    rawMessage VARCHAR
  ) WITH (
    KAFKA_TOPIC='splunk-syslog-tcp',
    VALUE_FORMAT='JSON'
  );
 ```

[source,sql]
```
CREATE STREAM SPLUNK_META AS SELECT SPLIT_TO_MAP(rawMessage, '||', '¥') PAYLOAD
FROM SPLUNK
EMIT CHANGES;
```

[source,sql]
```
CREATE STREAM TOHECWITHSPLUNK AS SELECT
  SPLUNK_META.PAYLOAD['sourcetype'] `sourcetype`,
  SPLUNK_META.PAYLOAD['source'] `source`,
  SPLUNK_META.PAYLOAD['time'] `time`,
  SPLUNK_META.PAYLOAD['index'] `index`,
  SPLUNK_META.PAYLOAD['event'] `event`,
  SPLUNK_META.PAYLOAD['host'] `host`
FROM SPLUNK_META SPLUNK_META
EMIT CHANGES;
```

3. Stream the data to Splunk with Kafka Connect.
I'm using ksqlDB to create the connector but you can use the Kafka Connect REST API directly if you want to. Kafka Connect is part of Apache Kafka and you don't have to use ksqlDB to use Kafka Connect.

[source,sql]
```
CREATE SINK CONNECTOR SPLUNKSINK WITH (
  'connector.class' = 'com.splunk.kafka.connect.SplunkSinkConnector',
  'topics' =  'TOHECWITHSPLUNK',
  'splunk.hec.uri'  = 'https://splunk_search:8088',
  'splunk.hec.token' = '3bca5f4c-1eff-4eee-9113-ea94c284478a',
  'value.converter' = 'org.apache.kafka.connect.storage.StringConverter',
  'splunk.hec.ssl.validate.certs' = 'false',
  'confluent.topic.bootstrap.servers' = 'kafka:9092',
  'splunk.hec.json.event.formatted' =  'true',
  'tasks.max' =  '1'
);
```

4. Stream the data to Elasticsearch with Kafka Connect
I'm using ksqlDB to create the connector but you can use the Kafka Connect REST API directly if you want to. Kafka Connect is part of Apache Kafka and you don't have to use ksqlDB to use Kafka Connect.
[source,sql]
```
CREATE SINK CONNECTOR SINK_ELASTIC_02 WITH (
'connector.class'                     = 'io.confluent.connect.elasticsearch.ElasticsearchSinkConnector',
'topics'                              = 'SPLUNK_META',
'key.converter'                       = 'org.apache.kafka.connect.storage.StringConverter',
'value.converter'                     = 'org.apache.kafka.connect.json.JsonConverter',
'value.converter.schemas.enable'      = 'false',
'connection.url'                      = 'http://elasticsearch:9200',
'type.name'                           = '_doc',
'key.ignore'                          = 'true',
'schema.ignore'                       = 'true');
```

5. configure your Splunk UF's (outputs.conf) to send data to the HF in this docker-compose instance. e.g. 192.168.1.101:9997
You should now be able to see data in both Splunk and ElastaicSearch from the Topic TOHECWITHSPLUNK/SPLUNK_META.

**Confluent KSQLDB Flow**
![image](Ksqldb.png)

6. Visualise your data in splunk or Elasticsearch
- Splunk - http://localhost:8000. (admin/Password1)
- Elastic - http://localhost:5601


**##NOTE: in this instance the props.conf is configured to forward all data to kafka, including all splunk internal data. To filter to only specific sourcetypes you can do the following:**
```
docker exec -it splunk_hf bash
sudo -i
vi /opt/splunk/etc/apps/splunk_forward_to_kafka/local/props.conf
change this 
[(?::){0}*] to [(?::){0}yoursourcetype*]
/opt/splunk/bin/splunk restart
```
**## For Multiline events use the below SEDCMD in the required sourcetype stanza to replace \n\r with a tab
```
SEDCMD-LF = s/(?ims)\n/ /g
SEDCMD-CR = s/(?ims)\r/ /g
```

-TBD
-Create eventgen with zeek data
# confluent_splunk_demo
