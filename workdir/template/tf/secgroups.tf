# AWS security groups

resource "aws_security_group" "bastion" {
  name = "bastion_sg"
  description = "Allow inbound SSH access to bastion"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags {
    Project = "${var.aws_project}"
  }
}

resource "aws_security_group" "egress" {
  name = "egress_sg"
  description = "Allow egress trffic from nodes"
  vpc_id = "${module.vpc.vpc_id}"

  egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags {
    Project = "${var.aws_project}"
  }
}

resource "aws_security_group" "allow_bastion_ssh" {
  name_prefix = "${module.vpc.vpc_id}"
  description = "Allow access from bastion host"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ "${aws_security_group.bastion.id}" ]
    self = false # don't add this sg as source for ingress rule
  }

  tags {
    Project = "${var.aws_project}"
  }

}

resource "aws_security_group" "allow_nodes" {
  name_prefix = "${module.vpc.vpc_id}"
  description = "Allow traffic between nodes"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  tags {
    Project = "${var.aws_project}"
  }
}

resource "aws_security_group" "master_elb" {
  name = "ose3-master-lb-sg"
  description = "External access to master ELB"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags {
    Project = "${var.aws_project}"
  }
}

resource "aws_security_group" "router_elb" {
  name = "ose3-router-lb-sg"
  description = "External access to router ELB"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags {
    Project = "${var.aws_project}"
  }
}

# allow traffic from ELBs (common sg for both master and router LBs)
resource "aws_security_group" "allow_from_elb" {
  name_prefix = "${module.vpc.vpc_id}"
  description = "Allow traffic from ELBs"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.router_elb.id}"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.router_elb.id}"]
  }
  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    security_groups = ["${aws_security_group.master_elb.id}"]
  }

  tags {
    Project = "${var.aws_project}"
  }
}
