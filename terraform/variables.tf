variable "aws_region" {
  type        = "string"
  description = "(Optional) AWS region code"
  default     = "eu-west-2"
}

variable "mqtt_instance_type" {
  type        = "string"
  description = "(Optional) AWS EC2 instance type to launch the MQTT server on"
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default     = "10.0.0.0/16"
}

variable "num_azs" {
  type        = "string"
  description = "Number of AZs to deploy VPC to"
  default     = "1"
}

variable "asg_max_size" {
  type        = "string"
  description = "Max number of MQTT servers to run"
  default     = "1"
}

variable "asg_min_size" {
  type        = "string"
  description = "Min number of MQTT servers to run"
  default     = "1"
}

variable "asg_desired_capacity" {
  type        = "string"
  description = "Desired number of MQTT servers to run"
  default     = "1"
}

variable "mosquitto_instance_port" {
  type        = "string"
  description = "Default listener port of mosquitto instances"
  default     = "1883"
}

variable "mqtt_lb_port" {
  type        = "string"
  description = "Default port of MQTT load balancer"
  default     = "8883"
}

variable "bastion_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0y8xWZCi9AC5P/LDzmW7PgXhQk6I2TYfXzdFok1sEbTkujZRfpcgxPuXS+fzLU/fxTE+3XK1KClpsiai+vl+KufoALx29cM61hzAxK+SZlbj0GCrbO2AKo/s6gRNY53KokD/7w2zPxTkao3k1UBDXFfWf6bDDJcZJH7y20EAoeDRQD7mfRqyEqt3W7er6Y+X2rNlmoxhCvKr5QwwJRn8+iI+Uioz4/gq1hxfxG4tlqks/Qn7j9zw1ClMdo+EDbhSko7IbqqlRHmge4ZOAD6KpqRdIl2Rv3lbheRRKDCR/FaCff3g0IjoQMkCWVc9N7vsNhDhu7JHTbFGOl0ADXqkb"
}
