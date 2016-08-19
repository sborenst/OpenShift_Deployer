{
  "Id": "Policy1466797511692",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1466797506841",
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${bucket_name}/*",
      "Principal": {
        "AWS": [
          "${bucket_access}"
        ]
      }
    }
  ]
}