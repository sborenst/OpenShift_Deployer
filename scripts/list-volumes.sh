aws ec2 describe-volumes --query 'Volumes[*].[ VolumeId,Size,State,AvailabilityZone ]' --output text
