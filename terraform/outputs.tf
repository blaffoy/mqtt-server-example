output "load_balancer_uri" {
  value = "${aws_lb.mqtt_nlb.dns_name}"
}
