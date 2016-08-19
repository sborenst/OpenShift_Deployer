# Define AWS infrastructure
## credentials need to be set in environment or in ~/.aws/credentials

provider "aws" {
  region = "${var.aws_region}"
}

# use community module to create VPC, subnets and internet gw
module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"

  name = "${var.vpc_name}"
  azs  = "${var.aws_azs}"
  cidr = "${var.vpc_cidr}"
  private_subnets = "${var.cidr_private_subnets}"
  public_subnets  = "${var.cidr_public_subnets}"

  enable_dns_hostnames = true
  enable_dns_support = true
}
