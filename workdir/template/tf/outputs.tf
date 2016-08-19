/*output "bastion" {
  value = "${aws_instance.bastion.public_dns}"
}

output "masters" {
  value = "${join(",", aws_instance.master.*.private_dns)}"
}

output "nodes" {
  value = "${join(",", aws_instance.node.*.private_dns)}"
}

output "infranodes" {
  value = "${join(",", aws_instance.node.*.private_dns)}"
}

output "etcd" {
  value = "${join(",", aws_instance.node.*.private_dns)}"
}
*/