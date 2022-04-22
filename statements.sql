-- example statements

create STREAM SPLUNK (
  `event` VARCHAR,
  `time` BIGINT,
  `host` VARCHAR,
  `source` VARCHAR,
  `sourcetype` VARCHAR,
  `index` VARCHAR
  ) WITH (
    KAFKA_TOPIC='splunk-s2s-events', VALUE_FORMAT='JSON');


CREATE STREAM CISCO_ASA as SELECT
  `event`,
  `source`,
  `sourcetype`,
  `index`  FROM SPLUNK
where `sourcetype` = 'cisco:asa'
EMIT CHANGES;

CREATE STREAM PAN_TRAFFIC WITH (KAFKA_TOPIC='PAN_TRAFFIC', PARTITIONS=1, REPLICAS=1) as SELECT
  `event`,
  `source`,
  `sourcetype`,
  `index`  
FROM SPLUNK
where ((`sourcetype` = 'pan:traffic') AND (`event` LIKE '%TRAFFIC%'))
EMIT CHANGES;

CREATE STREAM PAN_THREAT WITH (KAFKA_TOPIC='PAN_THREAT', PARTITIONS=1, REPLICAS=1) AS SELECT
  `event`,
  `source`,
  `sourcetype`,
  `index`
FROM SPLUNK
WHERE ((`sourcetype` = 'pan:traffic') AND (`event` LIKE '%THREAT%'))
EMIT CHANGES;

CREATE TABLE HOST_LOOKUP(
    ip varchar PRIMARY KEY, 
    hostname varchar, 
    domain varchar) 
WITH (KAFKA_TOPIC='host_lookup', VALUE_FORMAT='AVRO');

CREATE STREAM CISCO_ASA_FILTER_106023 WITH (KAFKA_TOPIC='CISCO_ASA_FILTER_106023', PARTITIONS=1, REPLICAS=1) AS SELECT
SPLUNK.`event` `event`,
SPLUNK.`source` `source`,
SPLUNK.`sourcetype` `sourcetype`,
SPLUNK.`index` `index`
FROM SPLUNK 
WHERE ((SPLUNK.`sourcetype` = 'cisco:asa') AND (NOT (SPLUNK.`event` LIKE '%ASA-4-106023%')))
EMIT CHANGES;




CREATE STREAM FIREWALLS (
`src` VARCHAR,
`messageID` BIGINT,
`index` VARCHAR,
`dest` VARCHAR,
`hostname` VARCHAR,
`protocol` VARCHAR,
`action` VARCHAR,
`srcport` BIGINT,
`sourcetype` VARCHAR,
`destport` BIGINT,
`timestamp` VARCHAR
) WITH (
    KAFKA_TOPIC='firewalls', value_format='JSON'
);



CREATE TABLE AGGREGATOR WITH (KAFKA_TOPIC='AGGREGATOR', KEY_FORMAT='JSON', PARTITIONS=1, REPLICAS=1) AS SELECT
  `hostname`,
  `messageID`,
  `action`,
  `src`,
  `dest`,
  `dest_port`,
  `sourcetype`,
  as_value(`hostname`) as hostname,
  as_value(`messageID`) as messageID,
  as_value(`action`) as action,
  as_value(`src`) as src,
  as_value(`dest`) as dest,
  as_value(`destport`) as dest_port,
  as_value(`sourcetype`) as sourcetype,
  TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm:ss', 'UTC') TIMESTAMP,
  300 DURATION,
  COUNT(*) COUNTS
FROM FIREWALLS FIREWALLS
WINDOW TUMBLING ( SIZE 300 SECONDS ) 
GROUP BY `sourcetype`, `action`, `hostname`, `messageID`, `src`, `dest`, `destport`
EMIT CHANGES;


CREATE STREAM FIREWALLS (
`src` VARCHAR,
`messageID` BIGINT PRIMARY KEY,
`index` VARCHAR,
`dest` VARCHAR,
`hostname` VARCHAR,
`protocol` VARCHAR,
`action` VARCHAR,
`srcport` BIGINT,
`location` VARCHAR,
`sourcetype` VARCHAR,
`destport` BIGINT,
`timestamp` VARCHAR
) WITH (
    KAFKA_TOPIC='firewalls', value_format='JSON', key_format='JSON'
);


#### FW_DENY Stream
CREATE STREAM FW_DENY WITH (KAFKA_TOPIC='FW_DENY', PARTITIONS=1, REPLICAS=1) AS SELECT *
FROM FIREWALLS FIREWALLS
WHERE (FIREWALLS.`action` = 'Deny')
EMIT CHANGES;



^(?<timestamp>\w{3}\s\d{2}\s\d{2}:\d{2}:\d{2})\s(?<hostname>[^\s]+)\s\%ASA-\d-(?<messageID>[^:]+):\s(?<action>[^\s]+)\s(?<protocol>[^\s]+)\ssrc\sinside:(?<src>[0-9\.]+)\/(?<srcport>[0-9]+)\sdst\soutside:(?<dest>[0-9\.]+)\/(?<destport>[0-9]+)