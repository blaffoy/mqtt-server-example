terraform {
  required_version = ">= 0.11.13"

  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}

provider "aws" {
  region  = "${var.aws_region}"
  version = "= 2.6.0"
}

data "aws_availability_zones" "azs" {}

data "aws_ami" "mqtt_image" {
  most_recent = "true"

  filter {
    name   = "name"
    values = ["mqtt-server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

resource "aws_security_group" "allow_mqtt" {
  name        = "allow_mqtt"
  description = "Allow mqtt inbound traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = "${var.mqtt_lb_port}"
    to_port     = "${var.mqtt_lb_port}"
    protocol    = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "mqtt_lc" {
  associate_public_ip_address = false
  image_id                    = "${data.aws_ami.mqtt_image.id}"
  instance_type               = "${var.mqtt_instance_type}"
  security_groups             = ["${aws_security_group.allow_mqtt.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "mqtt_asg" {
  name                      = "mqtt_server_asg"
  max_size                  = "${var.asg_max_size}"
  min_size                  = "${var.asg_min_size}"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = "${var.asg_desired_capacity}"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.mqtt_lc.name}"
  vpc_zone_identifier       = ["${var.subnet_id}"]

  tags = [
    {
      key                 = "Project"
      value               = "mqtt"
      propagate_at_launch = true
    },
    {
      key                 = "Managed_by"
      value               = "terraform"
      propagate_at_launch = true
    },
    {
      key                 = "Role"
      value               = "autoscaling_group"
      propagate_at_launch = false
    },
  ]
}

resource "aws_lb_target_group" "mqtt" {
  name     = "mqtt-target"
  port     = "${var.mqtt_lb_port}"
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_autoscaling_attachment" "asg_attachment_mqtt" {
  autoscaling_group_name = "${aws_autoscaling_group.mqtt_asg.id}"
  alb_target_group_arn   = "${aws_lb_target_group.mqtt.arn}"
}

resource "aws_lb" "mqtt_nlb" {
  name               = "mqtt"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${var.subnet_id}"]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.mqtt_nlb.arn}"
  port     = "${var.mqtt_lb_port}"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.mqtt.arn}"
  }
}
