# Pre-provision some volumes in each AZ, for use by metrics-deployer and others

resource "aws_ebs_volume" "pvs_1a" {
  availability_zone = "ap-southeast-2a"
  size = 10
  type = "gp2"
  count = "${var.pv_ebs_count}"

  tags {
    Name = "PV-1a-${count.index}"
    Project = "${var.aws_project}"
  }
}

resource "aws_ebs_volume" "pvs_1b" {
  availability_zone = "ap-southeast-2b"
  size = 10
  type = "gp2"
  count = "${var.pv_ebs_count}"

  tags {
    Name = "PV-1b-${count.index}"
    Project = "${var.aws_project}"
  }
}
