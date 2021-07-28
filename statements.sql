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




CREATE STREAM WinEventLog_Security as SELECT * FROM SPLUNK
where `sourcetype` = 'WinEventLog:Security'
EMIT CHANGES;