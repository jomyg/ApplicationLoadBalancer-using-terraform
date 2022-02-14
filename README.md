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
-rwxr-xr-x 1 root root 79991413 May  6 18:03 terraform 
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
The Basic configuration for terraform aws is completed. Now we need to initialize the terraform using the loaded values

## Application Load Balancer
> A load balancer serves as the single point of contact for clients. The load balancer distributes incoming application traffic across multiple targets, such as EC2 instances, in multiple Availability Zones.

The main components of an Application load balancer are 

- [Listeners](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html) : A listener checks for connection requests from clients, using the protocol and port that you configure. The rules that you define for a listener determine how the load balancer routes requests to its registered targets. Each rule consists of a priority, one or more actions, and one or more conditions. When the conditions for a rule are met, then its actions are performed. You must define a default rule for each listener, and you can optionally define additional rules.

- [Traget Group](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html) : Each target group routes requests to one or more registered targets, such as EC2 instances, using the protocol and port number that you specify. You can register a target with multiple target groups. You can configure health checks on a per target group basis. Health checks are performed on all targets registered to a target group that is specified in a listener rule for your load balancer.

The following diagram illustrates the basic components. 

![alt text](https://i.ibb.co/dQ7rc4k/Screenshot-from-2021-05-19-18-59-29.png)

### VPC Module behind the code

#### Create a file datasource.tf
```sh
data "aws_availability_zones" "az" {
    
  state = "available"
    
}
```
#### Create a file main.tf
```sh
# -------------------------------------------------------------------
# Vpc Creation
# -------------------------------------------------------------------

resource "aws_vpc" "vpc" {
    
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support = true  
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-vpc-${var.env}"
    project = var.project
    environment = var.env
  }
    
}


# -------------------------------------------------------------------
# InterNet GateWay Creation
# -------------------------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
   tags = {
    Name = "${var.project}-igw-${var.env}"
    project = var.project
     environment = var.env
  }
    
}


# -------------------------------------------------------------------
# Public Subnet 1
# -------------------------------------------------------------------

resource "aws_subnet" "public1" {
    
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, "3", 0)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.az.names[0]
  tags = {
    Name = "${var.project}-public1-${var.env}"
    project = var.project
     environment = var.env
  }
}

# -------------------------------------------------------------------
# Public Subnet 2
# -------------------------------------------------------------------

resource "aws_subnet" "public2" {
    
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, "3", 1)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.az.names[1]
  tags = {
    Name = "${var.project}-public2-${var.env}"
    project = var.project
     environment = var.env
  }
}

# -------------------------------------------------------------------
# Public Subnet 3
# -------------------------------------------------------------------
resource "aws_subnet" "public3" {
    
  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, "3", 2)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.az.names[2]
  tags = {
    Name = "${var.project}-public3-${var.env}"
    project = var.project
     environment = var.env
  }
}


# -------------------------------------------------------------------
# ElasticIp for NatGateway
# -------------------------------------------------------------------
resource "aws_eip" "nat" {
  vpc      = true
  tags = {
    Name = "${var.project}-nat-${var.env}"
    project = var.project
     environment = var.env
  }
}

# -------------------------------------------------------------------
#  NatGateway  Creation
# -------------------------------------------------------------------
resource "aws_nat_gateway" "nat" {
    
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
  tags = {
    Name = "${var.project}-nat-${var.env}"
    project = var.project
     environment = var.env
  }
  depends_on = [aws_internet_gateway.igw]
}

# -------------------------------------------------------------------
#  Public RouteTable
# -------------------------------------------------------------------

resource "aws_route_table" "public" {
    
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "${var.project}-public-${var.env}"
    project = var.project
     environment = var.env
  }
}


# -------------------------------------------------------------------
#  Public RouteTable association
# -------------------------------------------------------------------
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.public.id
}
```
#### Create a file output.tf
```sh
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_public1_id" {
  value = aws_subnet.public1.id
}

output "subnet_public2_id" {
  value = aws_subnet.public2.id
}

output "subnet_public3_id" {
  value = aws_subnet.public3.id
}
```
#### Create a file variables.tf
```sh
variable "vpc_cidr" {
    
  default = "172.16.0.0/16"
    
}

variable "project" {
    
  default = "example"
    
}


variable "env" {
    
  default = "test"
    
}
```


## Conclusion

Here is a simple document on how to use Terraform to build an AWS ALB Application load balancer.

#### ⚙️ Connect with Me

<p align="center">
<a href="mailto:jomyambattil@gmail.com"><img src="https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white"/></a>
<a href="https://www.linkedin.com/in/jomygeorge11"><img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white"/></a> 
<a href="https://www.instagram.com/therealjomy"><img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white"/></a><br />
