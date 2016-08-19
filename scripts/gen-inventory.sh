#! /usr/bin/env python
# pip install boto3
import boto3
import sys
ec2 = boto3.resource("ec2")

nodes = {}
for nodetype in ['Master', 'Node', 'Infranode']:
  node_filter=[{'Name': 'instance-state-name', 'Values':['running']},
               {'Name': 'tag:Nodetype', 'Values': ['{0}'.format(nodetype)]}
               ]
  nodes[nodetype] = ec2.instances.filter(Filters=node_filter)

print """[OSEv3:children]
masters
nodes
etcd
# no lb group defined, handled by AWS ELB
# no nfs group defined, will use S3 storage for registry and ELB backend for other PVs
"""

print "[masters]"
for i in nodes['Master']:
  print i.public_dns_name

print ""

print "[etcd]"
for i in nodes['Master']:
  print i.public_dns_name

print ""

c = 0
print "[nodes]"
for i in nodes['Node']:
  c = c + 1
  #print "{0} openshift_hostname='node{1}.internal.sborenst.opentlc.com' openshift_node_labels=\"{{'region': 'primary', 'zone': '{2}'}}\"".format(i.public_dns_name, c,  i.placement['AvailabilityZone'])
  print "{0} openshift_node_labels=\"{{'region': 'primary', 'zone': '{2}'}}\"".format(i.public_dns_name, c,  i.placement['AvailabilityZone'])

c = 0
for i in nodes['Infranode']:
  c = c + 1
  #print "{0} openshift_hostname='infranode{1}.internal.sborenst.opentlc.com' openshift_node_labels=\"{{'region': 'infra', 'zone': '{2}'}}\"".format(i.public_dns_name,c, i.placement['AvailabilityZone'])
  print "{0} openshift_node_labels=\"{{'region': 'infra', 'zone': '{2}'}}\"".format(i.public_dns_name,c, i.placement['AvailabilityZone'])

c = 0
for i in nodes['Master']:
  c = c + 1
  #print "{0} openshift_hostname='master{1}.internal.sborenst.opentlc.com' openshift_node_labels=\"{{'region': 'primary', 'zone': '{2}'}}\" openshift_schedulable=False".format(i.public_dns_name,c,  i.placement['AvailabilityZone'])
  print "{0} openshift_node_labels=\"{{'region': 'primary', 'zone': '{2}'}}\" openshift_schedulable=False".format(i.public_dns_name,c,  i.placement['AvailabilityZone'])

print ""
print open(str(sys.argv[1])).read()
