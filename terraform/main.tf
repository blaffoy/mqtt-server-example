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

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
}

data "aws_availability_zones" "azs" {}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  count                   = "${var.num_azs}"
  cidr_block              = "${cidrsubnet(cidrsubnet(var.vpc_cidr, 4, 1), 4, count.index)}"
  availability_zone       = "${data.aws_availability_zones.azs.names[count.index]}"
  map_public_ip_on_launch = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private_rt" {
  count  = "${var.num_azs}"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table_association" "private_rta" {
  count          = "${var.num_azs}"
  subnet_id      = "${element(aws_subnet.private_subnet.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.private_rt.*.id, count.index)}"
}

resource "aws_internet_gateway" "default_igw" {
  vpc_id = "${aws_vpc.main.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.main.id}"
  count                   = "${var.num_azs}"
  cidr_block              = "${cidrsubnet(cidrsubnet(var.vpc_cidr, 4, 2), 4, count.index)}"
  availability_zone       = "${data.aws_availability_zones.azs.names[count.index]}"
  map_public_ip_on_launch = true
}

resource "aws_default_route_table" "public_rt" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_default_route_table.public_rt.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default_igw.id}"
  depends_on             = ["aws_vpc.main"]
}

resource "aws_route_table_association" "public_rta" {
  count          = "1"
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_default_route_table.public_rt.id}"
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
  name                        = "mqtt_server"
  associate_public_ip_address = false
  image_id                    = "${data.aws_ami.mqtt_image.id}"
  instance_type               = "${var.mqtt_instance_type}"
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
  vpc_zone_identifier       = ["${aws_subnet.private_subnet.*.id}"]

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
