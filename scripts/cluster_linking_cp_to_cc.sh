# Refer to the steps of source initiated CL in https://docs.confluent.io/platform/current/multi-dc-deployments/cluster-linking/hybrid-cp.html#mirror-data-from-on-premises-to-ccloud



# create the destination half of the CL (CC side)

CC_CLUSTER_ID=lkc-o32kjj
CP_CLUSTER_ID=jWyZhCTMTmKsN4AyywVwfg

confluent api-key create --resource $CC_CLUSTER_ID



confluent kafka link create from-on-prem-link --cluster $CC_CLUSTER_ID \
  --source-cluster-id $CP_CLUSTER_ID \
  --config-file $PWD/clusterlink-hybrid-dst.config \
  --source-bootstrap-server 0.0.0.0


Created cluster link "from-on-prem-link".

confluent kafka link list --cluster $CC_CLUSTER_ID

confluent kafka link describe <link-name> --cluster $CC_CLUSTER_ID

# create the source half fo the CC (CP side)
kafka-cluster-links --bootstrap-server localhost:9092 \
     --create --link from-on-prem-link \
     --config-file $PWD/clusterlink-CP-src.config \
     --cluster-id $CC_CLUSTER_ID --command-config $PWD/CP-command.config



kafka-cluster-links --list --bootstrap-server localhost:9092 --command-config $PWD/CP-command.config

# create mirror topics 

confluent kafka mirror create from-on-prem --link from-on-prem-link

confluent kafka mirror list --cluster $CC_CLUSTER_ID

