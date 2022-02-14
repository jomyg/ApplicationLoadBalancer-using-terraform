# ApplicationLoadBalancer-using-terraform

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)]()

An Application Load Balancer functions at the application layer, the seventh layer of the Open Systems Interconnection (OSI) model. After the load balancer receives a request, it evaluates the listener rules in priority order to determine which rule to apply, and then selects a target from the target group for the rule action. You can configure listener rules to route requests to different target groups based on the content of the application traffic. Routing is performed independently for each target group, even when a target is registered with multiple target groups. You can configure the routing algorithm used at the target group level. The default routing algorithm is round robin; alternatively, you can specify the least outstanding requests routing algorithm.

## Description:

The Application Load Balancer is a feature of Elastic Load Balancing that allows a developer to configure and route incoming end-user traffic to applications based in the AWS public cloud. Application Load Balancer enables content-based routing and allows requests to be routed to different applications behind a single load balance. While the Classic Load Balancer doesn't do that, a single ELB can host single application. Application Load Balancer works in Layer 7 of the OSI reference model for how applications communicate over a network.

Terraform is a tool for building infrastructure with various technologies including Amazon AWS, Microsoft Azure, Google Cloud, and vSphere.
Here is a simple document on how to use Terraform to build an AWS ALB Application load balancer.

## Features

- Easy to customise with just a quick look with terrafrom code
- AWS VPC informations are created as a module and can easily changed
- Project name is appended to the resources that are creating which will make easier to identify the resources.

## Terraform Installation
- Create an IAM user/Role on your AWS console that have access to create the required resources.
- Create a dedicated directory where you can create terraform configuration files.
- Download Terrafom, click here [Terraform](https://www.terraform.io/downloads.html).
- Install Terraform, click here [Terraform installation](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)

Use the following command to install Terraform
```sh
wget https://releases.hashicorp.com/terraform/0.15.3/terraform_0.15.3_linux_amd64.zip
unzip terraform_0.15.3_linux_amd64.zip 
ls -l
-rwxr-xr-x 1 root root 79991413 May  6 18:03 terraform  <<=======
-rw-r--r-- 1 root root 32743141 May  6 18:50 terraform_0.15.3_linux_amd64.zip
mv terraform /usr/bin/
which terraform 
/usr/bin/terraform
```
#### Lets create a file for declaring the variables. 
> Note : The terrafom files must be created with .tf extension. 

This is used to declare the variable and pass values to terraform source code: vi variables.tf
```sh
variable "project_vpc_cidr" {

  default = "172.24.0.0/16"
}

variable "project_name" {
    
  default = "zomato"
}

variable "project_env" {
    
  default = "dev"
}
```
#### Create a file provider.tf
```sh
provider "aws" {
  region = "ap-south-1"
}
```
#### Create a file setup.sh
```sh
#!/bin/bash


echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "LANG=en_US.utf-8" >> /etc/environment
echo "LC_ALL=en_US.utf-8" >> /etc/environment

echo "password@123" | passwd root --stdin
sed  -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
service sshd restart




yum install httpd php -y

cat <<EOF > /var/www/html/index.php
<?php
\$output = shell_exec('echo $HOSTNAME');
echo "<h1><center><pre>\$output</pre></center></h1>";
echo "<h1><center>Application 2</center></h1>"
?>
EOF

service httpd restart
chkconfig httpd on
```

#### Create a file main.tf
```sh
variable "application" {
  default = "zomato"
}

variable "ami-id" {
    default = "ami-03fa4afc89e4a8a09"
}

variable "type" {
    default = "t2.micro"
}

module "vpc" {
    
  source   = "/var/terraform/modules/vpc/"
  vpc_cidr = var.project_vpc_cidr
  project  = var.project_name
  env      = var.project_env
  
}


# --------------------------------------------------------------------
# Creating SecurityGroup free-bird
# --------------------------------------------------------------------

resource "aws_security_group" "free-bird" {
    
  name        = "${var.project_name}-webserver-${var.project_env}"
  description = "allow 22, 80,443 traffic"
  vpc_id      = module.vpc.vpc_id


  ingress {
    description      = ""
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
    
   ingress {
    description      = ""
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
   
  ingress {
    description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
    
    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-webserver-${var.project_env}"
    project = var.project_name
     environment = var.project_env
  }
}

resource "aws_launch_configuration" "lc" {
  
  name_prefix       = "${var.application}-"  
  image_id          = var.ami-id 
  instance_type     = var.type
  security_groups =[aws_security_group.free-bird.id] 
  user_data         = file("setup.sh") 
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {

  name_prefix             = "${var.application}-"
  launch_configuration    = aws_launch_configuration.lc.id
  health_check_type       = "EC2"
  min_size                = "2"
  max_size                = "2"
  desired_capacity        = "2"
  vpc_zone_identifier     = [ module.vpc.subnet_public2_id ]
  target_group_arns       = [aws_lb_target_group.tg.arn]
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "${var.application}"
  }
  
  tag {
    key = "project"
    propagate_at_launch = true
    value = "${var.application}"
  }
    
    
  lifecycle {
    create_before_destroy = true
  }
}



##########################################################

resource "aws_lb_target_group" "tg" {
    
    
  name_prefix                   = "zomato"
  port                          = 80
  protocol                      = "HTTP"
  load_balancing_algorithm_type = "round_robin"
  deregistration_delay          = 5
  vpc_id      = module.vpc.vpc_id
    stickiness {
    enabled = false
    type    = "lb_cookie"
    cookie_duration = 60
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = 200
    
  }

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_lb" "alb" {
  name_prefix                   = "zomato"
  internal                      = false
  load_balancer_type            = "application"
  security_groups               = [aws_security_group.free-bird.id]
  subnets                       = [ module.vpc.subnet_public2_id , module.vpc.subnet_public1_id ]
  enable_deletion_protection    = false
  depends_on                    = [ aws_lb_target_group.tg ]
  tags = {
     Name = "${var.application}"
   }
}


resource "aws_lb_listener" "listner" {
  
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found "
      status_code  = "500"
   }
  }
    
  depends_on = [  aws_lb.alb ]
}


resource "aws_lb_listener_rule" "main" {

  listener_arn = aws_lb_listener.listner.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["webapp.jomygeorge.xyz"]
    }
  }
}
```
