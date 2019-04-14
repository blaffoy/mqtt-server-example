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

variable "vpc_id" {
  description = "ID of target VPC"
  default     = ""
}

variable "subnet_id" {
  description = "ID of target subnet"
  default     = ""
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

variable "mqtt_lb_port" {
  description = "Default port of MQTT load balancer"
  default     = 8883
}
