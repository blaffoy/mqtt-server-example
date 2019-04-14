# mqtt-server-example

Learning project for deploying an MQTT server in AWS EC2

Based on the "immutable image" deployment technique, this project uses packer and ansible to create an AMI, which is then deployed to EC2 in an autoscaling group behind a load balancer using terraform.


# Dependencies

Project built with

- packer 1.4.0
- terraform 0.11.13
- aws-cli 1.16.140
- ansible-playbook 2.2.1.0

Depends on well configured AWS profile under ~/.aws with permissions to create and update EC2 and VPC resources

# Building the image

For simplicity, I've used off-the-shelf ansible roles to set up the AMI (kudos to geerlingguy and lnovara). The following command will create the image and save the AMI to you AWS account.

```
$ make build
```

# Deploying terraform

For simplicity, this project has been implemented with a local backend. Future development to make more production-ready will use S3 backend

## terraform variables

Easy terraform variables are set in the file `environment/default.tfvars`. To deploy yourself, update that file, or create a new environment. `vpc_zone_identifier` must be set.


```
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
```

## Terraform commands

To initialise the terraform project

```
terraform init terraform
```

To create a terraform plan in `./.terraform/terraform.tfplan` with variables in `./environment/default.tfvars`

```
terraform plan -var-file environment/default.tfvars -out .terraform/terraform.tfplan terraform/
```

To apply this plan to your AWS account

```
terraform apply ".terraform/terraform.tfplan"
```
