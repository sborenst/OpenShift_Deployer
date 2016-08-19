#!/bin/bash

rm -rf /etc/yum.repos.d/*
yum clean all
subscription-manager register --force --username='${rhn_username}' --password='${rhn_password}'
subscription-manager attach --pool=${rhn_poolid}
subscription-manager repos --disable='*'
subscription-manager repos \
      --enable="rhel-7-server-rpms" \
      --enable="rhel-7-server-extras-rpms" \
      --enable="rhel-7-server-ose-3.2-rpms"

yum clean all
yum repolist
yum -y install atomic-openshift-utils
yum update -y

[ -d /etc/aws ] || mkdir -p /etc/aws
az=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
cat << EOF > /etc/aws/aws.conf
[Global]
Zone = $az
EOF
