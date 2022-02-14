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
