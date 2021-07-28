Streaming data from Splunk to Kafka using KSQLDB for filtering, while keeping all the Splunk MetaData (source,sourcetype,host,event) <jmirza@confluent.io>
v1.00, 3 November 2020

TL;DR
```
QuickStart
1. git clone https://github.com/JohnnyMirza/confluent_splunk_demo.git
2. docker-compose up -d
3. copy and paste the queries in the statements.sql to the editor in control center localhost:9021 file
3. Configure Splunk UF’s to send to the above instance
```


Notes:
Kafka-Connect needs 8GB of ram, set this in your docker resource settings