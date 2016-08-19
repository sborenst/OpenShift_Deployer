# S3 bucket and template for bucket policy

resource "template_file" "registry-policy" {
  template = "${file("registry-policy.tpl")}"
  vars {
    bucket_name = "${var.s3_registry_bucket_name}"
    bucket_access = "${var.s3_registry_bucket_access}"
  }
}

resource "aws_s3_bucket" "registry" {
    bucket = "${var.s3_registry_bucket_name}"
    acl = ""
    policy = "${template_file.registry-policy.rendered}"
    force_destroy = true

    tags {
      Project = "${var.aws_project}"
    }
}
