# Load balancers and DNS records for master and router
# Use TCP


## Setting Master LB

resource "aws_elb" "master" {
  name = "ose3-master-lb"
  subnets = [ "${split(",", module.vpc.public_subnets)}" ]
  security_groups = [ "${aws_security_group.master_elb.id}" ]
  cross_zone_load_balancing = true

  listener {
    instance_port = 8443
    instance_protocol = "tcp"
    lb_port = 8443
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:8443"
    interval = 10
  }

  tags {
    Project = "${var.aws_project}"
  }
}

resource "aws_route53_zone" "public" {
  name = "${var.public_zone_fqdn}"
}

resource "aws_route53_zone" "private" {
  name = "${var.private_zone_fqdn}"
}


resource "aws_route53_record" "ose3" {
  zone_id = "${aws_route53_zone.public.zone_id}"
  name = "${var.master_public_dns}"  type = "A"

  alias {
    name = "${aws_elb.master.dns_name}"
    zone_id = "${aws_elb.master.zone_id}"
    evaluate_target_health = false
  }
}

## Setting HA Proxy Router LB

resource "aws_elb" "router" {
  name = "ose3-router-lb"
  subnets = [ "${split(",", module.vpc.public_subnets)}" ]
  security_groups = [ "${aws_security_group.router_elb.id}" ]
  cross_zone_load_balancing = true

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 443
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:80"
    interval = 10
  }

  tags {
    Project = "${var.aws_project}"
  }
}

resource "aws_route53_record" "wildcard" {
  zone_id = "${aws_route53_zone.public.zone_id}"
  name = "${var.apps_public_dns}"
  type = "A"

  alias {
    name = "${aws_elb.router.dns_name}"
    zone_id = "${aws_elb.master.zone_id}"
    evaluate_target_health = false
  }
}
