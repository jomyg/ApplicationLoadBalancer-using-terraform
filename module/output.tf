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
