output "load_balancer_uri" {
  value = "${aws_elb.mqtt_lb.dns_name}"
}

output "nat_eips" {
  value = ["${aws_eip.nat_eips.*.public_ip}"]
}
