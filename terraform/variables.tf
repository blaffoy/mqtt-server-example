variable "aws_region" {
  type        = "string"
  description = "(Optional) AWS region code"
  default     = "eu-west-2"
}

variable "vpc_zone_identifier" {
  type        = "list"
  description = "List of subnet IDs to deploy into, this project assumes the existence of a VPC and public subnets"
  default     = []
}

variable "mqtt_instance_type" {
  type        = "string"
  description = "(Optional) AWS EC2 instance type to launch the MQTT server on"
  default     = "t2.micro"
}
