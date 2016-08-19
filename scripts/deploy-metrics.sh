#! /bin/bash

# script to deploy cluster metrics, run on master as system:admin

oc login -u system:admin
oc project openshift-infra

oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
API

oc adm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster

oc secrets new metrics-deployer nothing=/dev/null

oc process -f /usr/share/openshift/examples/infrastructure-templates/enterprise/metrics-deployer.yaml -v \
    HAWKULAR_METRICS_HOSTNAME=https://hawkular-metrics.cloudapps.test-ml.sborenst.opentlc.com,CASSANDRA_PV_SIZE=10Gi \
    | oc create -f -
