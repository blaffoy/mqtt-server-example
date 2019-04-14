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

resource "aws_launch_configuration" "mqtt_lc" {
  name = "mqtt_server"
  image_id      = "${data.aws_ami.mqtt_image.id}"
  instance_type = "${var.mqtt_instance_type}"
}

resource "aws_autoscaling_group" "mqtt_asg" {
  name                      = "mqtt_server_asg"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.mqtt_lc.name}"
  vpc_zone_identifier       = "${var.vpc_zone_identifier}"

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
      propagate_at_launch = true
    }
  ]
}
