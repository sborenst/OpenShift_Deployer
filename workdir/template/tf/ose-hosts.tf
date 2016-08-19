# Define hosts/instances part of the OSE3 installation
# We do not have pre-baked AMIs for OSE nodes, but will still prefer to deploy via ASGs with min/max = <desired number of nodes>

# Userdata bootstrap template
resource "template_file" "userdata" {
  template = "${file("bootstrap.tpl")}"
  vars {
    rhn_username = "${var.rhn_username}"
    rhn_password = "${var.rhn_password}"
    rhn_poolid = "${var.rhn_poolid}"
  }

  lifecycle { create_before_destroy = true }
}

## Launch configurations
resource "aws_launch_configuration" "bastion_conf" {
  name_prefix = "bastion-lc-"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_types, "bastion")}"
  key_name = "${var.aws_key_name}"
  security_groups = [ "${aws_security_group.bastion.id}" ]
  associate_public_ip_address = true
  user_data = "${template_file.userdata.rendered}"

  lifecycle { create_before_destroy = true }
}

resource "aws_launch_configuration" "master_conf" {
  name_prefix = "master-lc-"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_types, "master")}"
  key_name = "${var.aws_key_name}"
  security_groups = [ "${aws_security_group.allow_bastion_ssh.id}",
                      "${aws_security_group.allow_nodes.id}",
                      "${aws_security_group.allow_from_elb.id}",
                      "${aws_security_group.egress.id}" ]
  associate_public_ip_address = false
  user_data = "${template_file.userdata.rendered}"

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 60
    delete_on_termination = true
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_launch_configuration" "etcd_conf" {
  name_prefix = "etcd-lc-"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_types, "etcd")}"
  key_name = "${var.aws_key_name}"
  security_groups = [ "${aws_security_group.allow_bastion_ssh.id}",
                      "${aws_security_group.allow_nodes.id}",
                      "${aws_security_group.egress.id}" ]
  associate_public_ip_address = false
  user_data = "${template_file.userdata.rendered}"

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = true
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_launch_configuration" "node_conf" {
  name_prefix = "node-lc-"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_types, "node")}"
  key_name = "${var.aws_key_name}"
  security_groups = [ "${aws_security_group.allow_bastion_ssh.id}",
                       "${aws_security_group.allow_nodes.id}",
                       "${aws_security_group.egress.id}" ]
  associate_public_ip_address = true
  user_data = "${template_file.userdata.rendered}"


  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 60
    delete_on_termination = true
  }

  lifecycle { create_before_destroy = true }

}

resource "aws_launch_configuration" "infranode_conf" {
  name_prefix = "infranode-lc-"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.instance_types, "infranode")}"
  key_name = "${var.aws_key_name}"
  security_groups = [ "${aws_security_group.allow_bastion_ssh.id}",
                      "${aws_security_group.allow_nodes.id}",
                      "${aws_security_group.allow_from_elb.id}",
                      "${aws_security_group.egress.id}" ]
  associate_public_ip_address = true
  user_data = "${template_file.userdata.rendered}"

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 60
    delete_on_termination = true
  }

  lifecycle { create_before_destroy = true }

}

variable "count" {
  default = 0
}

## ASGs
resource "aws_autoscaling_group" "bastion_asg" {
  vpc_zone_identifier = ["${split(",", module.vpc.public_subnets)}"]
  name="BastionASG"
  min_size = 1
  max_size = 1
  health_check_type = "EC2"
  force_delete = false
  launch_configuration = "${aws_launch_configuration.bastion_conf.name}"


  tag {
    key = "Nodetype"
    value = "Bastion"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "${format("bastion-%03d", count.index + 1)}"
    propagate_at_launch = true
  }


  tag = {
    key = "Project"
    value = "${var.aws_project}"
    propagate_at_launch = true
  }
}



resource "aws_autoscaling_group" "master_asg" {
  vpc_zone_identifier = ["${split(",", module.vpc.public_subnets)}"]
  name="MasterASG"
  min_size = "${lookup(var.instance_counts, "master")}"
  max_size = "${lookup(var.instance_counts, "master")}"
  health_check_type = "EC2"
  force_delete = false
  launch_configuration = "${aws_launch_configuration.master_conf.name}"
  load_balancers = [ "${aws_elb.master.id}" ]
  tag {
    key = "Nodetype"
    value = "Master"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "${format("master-%03d", count.index + 1)}"
    propagate_at_launch = true
  }


  tag = {
    key = "Project"
    value = "${var.aws_project}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "etcd_asg" {
  vpc_zone_identifier = ["${split(",", module.vpc.public_subnets)}"]
  name="EtcdASG"

  min_size = "${lookup(var.instance_counts, "etcd")}"
  max_size = "${lookup(var.instance_counts, "etcd")}"
  health_check_type = "EC2"
  force_delete = false
  launch_configuration = "${aws_launch_configuration.etcd_conf.name}"

  tag {
    key = "Nodetype"
    value = "Etcd"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "${format("etcd-%03d", count.index + 1)}"
    propagate_at_launch = true
  }

  tag = {
    key = "Project"
    value = "${var.aws_project}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "node_asg" {
  vpc_zone_identifier = ["${split(",", module.vpc.public_subnets)}"]
  name="NodeASG"

  min_size = "${lookup(var.instance_counts, "node")}"
  max_size = "${lookup(var.instance_counts, "node")}"
  health_check_type = "EC2"
  force_delete = false
  launch_configuration = "${aws_launch_configuration.node_conf.name}"

  tag {
    key = "Nodetype"
    value = "Node"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "${format("node-%03d", count.index + 1)}"
    propagate_at_launch = true
  }


  tag = {
    key = "Project"
    value = "${var.aws_project}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "infranode_asg" {
  vpc_zone_identifier = ["${split(",", module.vpc.public_subnets)}"]
  name="InfranodeASG"
  min_size = "${lookup(var.instance_counts, "infranode")}"
  max_size = "${lookup(var.instance_counts, "infranode")}"
  health_check_type = "EC2"
  force_delete = false
  launch_configuration = "${aws_launch_configuration.infranode_conf.name}"
  load_balancers = [ "${aws_elb.router.id}" ]

  tag {
    key = "Nodetype"
    value = "Infranode"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value =  "${format("infranode-%03d", count.index + 1)}"
    propagate_at_launch = true
  }
  tag = {
    key = "Project"
    value = "${var.aws_project}"
    propagate_at_launch = true
  }
}
