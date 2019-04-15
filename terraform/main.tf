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

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

resource "aws_eip" "nat_eips" {
  count = "${var.num_azs}"
  vpc = true
}

resource "aws_nat_gateway" "default_ngw" {
  count         = "${var.num_azs}"
  allocation_id = "${element(aws_eip.nat_eips.*.id,count.index)}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id,count.index)}"

  depends_on = ["aws_internet_gateway.default_igw"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "private_route" {
  count                  = "${var.num_azs}"
  route_table_id         = "${element(aws_route_table.private_rt.*.id,count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.default_ngw.*.id,count.index)}"
  depends_on             = ["aws_route_table.private_rt"]
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

resource "aws_security_group" "bastion" {
    name = "vpc_bastion"
    description = "Allow incoming ssh connections."

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "public" {
    name = "vpc_public"

    ingress {
        from_port = "${var.mqtt_lb_port}"
        to_port = "${var.mqtt_lb_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "private" {
    name = "vpc_private"
    description = "Allow connections to private subnet"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        security_groups = ["${aws_security_group.bastion.id}"]
    }

    ingress {
        from_port = "${var.mosquitto_instance_port}"
        to_port = "${var.mosquitto_instance_port}"
        protocol = "tcp"
        security_groups = ["${aws_security_group.public.id}"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key"
  public_key = "${var.bastion_public_key}"
}

data "aws_ami" "bastion_image" {
  most_recent = "true"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_launch_configuration" "bastion_lc" {
  associate_public_ip_address = true
  image_id                    = "${data.aws_ami.bastion_image.id}"
  instance_type               = "t2.micro"
  key_name                    = "bastion_key"
  security_groups             = ["${aws_security_group.bastion.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion_asg" {
  name                      = "bastion_asg"
  max_size                  = "1"
  min_size                  = "1"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = "1"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.bastion_lc.name}"
  vpc_zone_identifier       = ["${aws_subnet.public_subnet.*.id}"]
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
  associate_public_ip_address = false
  image_id                    = "${data.aws_ami.mqtt_image.id}"
  instance_type               = "${var.mqtt_instance_type}"
  key_name                    = "bastion_key"
  security_groups             = ["${aws_security_group.private.id}", "${aws_default_security_group.default.id}"]

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

resource "aws_elb" "mqtt_lb" {
  name               = "mqtt-load-balancer"
  listener {
    instance_port     = "${var.mosquitto_instance_port}"
    instance_protocol = "tcp"
    lb_port           = "${var.mqtt_lb_port}"
    lb_protocol       = "tcp"
  }

  subnets      = ["${aws_subnet.private_subnet.*.id}"]
  security_groups = ["${aws_security_group.public.id}"]
  source_security_group = "${aws_security_group.public.id}"
}

resource "aws_autoscaling_attachment" "mqtt_asg_lb" {
  autoscaling_group_name = "${aws_autoscaling_group.mqtt_asg.id}"
  elb                    = "${aws_elb.mqtt_lb.id}"
}
