output "load_balancer_uri" {
  value = "${aws_lb.mqtt_nlb.dns_name}"
}

output "nat_eips" {
  value = ["${aws_eip.nat_eips.*.public_ip}"]
}
