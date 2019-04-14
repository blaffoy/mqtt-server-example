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
