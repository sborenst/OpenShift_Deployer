#! /bin/bash
# http://serverfault.com/questions/578921/how-would-you-go-about-listing-instances-using-aws-cli-in-certain-vpc-with-the-t

case "$1" in
  master)
    nodefilter="Name=tag:Nodetype,Values=Master" ;;
  node)
    nodefilter="Name=tag:Nodetype,Values=Node Name=tag:Nodetype,Values=Infranode" ;;
  infra)
    nodefilter="Name=tag:Nodetype,Values=Infranode" ;;
  bastion)
    nodefilter="Name=tag:Nodetype,Values=Bastion" ;;
    *) ;;
esac
aws ec2 describe-instances --output text \
  --filters "Name=instance-state-name,Values=running" \
   $nodefilter \
  --query 'Reservations[*].Instances[*].[ PublicDnsName,PrivateDnsName,Placement.AvailabilityZone,Tags[?Key==`Nodetype`].Value[] ]' | \
  sed '$!N;s/\n/ /' | sort -k 3
