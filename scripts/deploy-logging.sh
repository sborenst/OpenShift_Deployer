#! /bin/bash

# script to deploy aggregated logging, ref https://docs.openshift.com/enterprise/3.2/install_config/aggregate_logging.html

# set up dedicated project
oc login -u system:admin
oc adm new-project logging
oc project logging

oc secrets new logging-deployer nothing=/dev/null

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: logging-deployer
secrets:
- name: logging-deployer
API
oc policy add-role-to-user edit --serviceaccount logging-deployer

oc adm policy add-scc-to-user privileged system:serviceaccount:logging:aggregated-logging-fluentd
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:logging:aggregated-logging-fluentd

oc new-app logging-deployer-template \
             --param KIBANA_HOSTNAME=kibana.cloudapps.test-ml.sborenst.opentlc.com \
             --param KIBANA_OPS_HOSTNAME=kibana-ops..cloudapps.test-ml.sborenst.opentlc.com \
             --param ES_CLUSTER_SIZE=1 \
             --param PUBLIC_MASTER_URL=https://ose3.oselab.martineg.net:8443
sleep 10s

oc new-app logging-support-template

# manually import images
oc import-image logging-auth-proxy:3.2.0 --from registry.access.redhat.com/openshift3/logging-auth-proxy:3.2.0
oc import-image logging-kibana:3.2.0 --from registry.access.redhat.com/openshift3/logging-kibana:3.2.0
oc import-image logging-elasticsearch:3.2.0 --from registry.access.redhat.com/openshift3/logging-elasticsearch:3.2.0
oc import-image logging-fluentd:3.2.0 --from registry.access.redhat.com/openshift3/logging-fluentd:3.2.0

# optionally manually add persistent volumes to each es deployment
# oc volume dc/logging-es-rca2m9u8 \
#         --add --overwrite --name=elasticsearch-storage \
#         --type=persistentVolumeClaim --claim-name=logging-es-1
#
