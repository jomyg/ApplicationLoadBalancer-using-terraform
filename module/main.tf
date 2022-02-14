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
