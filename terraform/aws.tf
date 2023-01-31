resource "random_id" "vpc_display_id" {
    byte_length = 4
}
# ------------------------------------------------------
# PROVIDER
# ------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
}
# ------------------------------------------------------
# VPC
# ------------------------------------------------------
resource "aws_vpc" "main" { 
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "gko-prework-uc1-${random_id.vpc_display_id.hex}"
    }
}
# ------------------------------------------------------
# SUBNETS
# ------------------------------------------------------
resource "aws_subnet" "public_subnets" {
    count = 3
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.${count.index+1}.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "gko-prework-uc1-public-subnet-${count.index}-${random_id.vpc_display_id.hex}"
    }
}
# ------------------------------------------------------
# IGW
# ------------------------------------------------------
resource "aws_internet_gateway" "igw" { 
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "gko-prework-uc1-igw-${random_id.vpc_display_id.hex}"
    }
}
# ------------------------------------------------------
# ROUTE TABLE
# ------------------------------------------------------
resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "gko-prework-uc1-route-table-${random_id.vpc_display_id.hex}"
    }
}
resource "aws_route_table_association" "subnet_associations" {
    count = 3
    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.route_table.id
}
# ------------------------------------------------------
# SECURITY GROUP
# ------------------------------------------------------
resource "aws_security_group" "rabbitmq_sg" {
    name = "rabbitmq_security_group_${random_id.vpc_display_id.hex}"
    description = "${local.aws_description}"
    vpc_id = aws_vpc.main.id
    egress {
        description = "Allow all outbound."
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        description = "RabbitMQ"
        from_port = 5672
        to_port = 5672
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
        Name = "gko-prework-uc1-sg-${random_id.vpc_display_id.hex}"
    }
}
# ------------------------------------------------------
# RABBITMQ
# ------------------------------------------------------
#resource "aws_mq_broker" "rabbitmq" {
#  broker_name = "flower_co"

#  engine_type        = "RabbitMQ"
#  engine_version     = "3.10.10"
#  host_instance_type = "mq.t3.micro"
#  publicly_accessible = "true"
  #security_groups    = ["${aws_security_group.rabbitmq_sg.id}"]

#  user {
#    username = "ExampleUser"
#    password = "MindTheGapLongPassword"
#  }
#}

# ------------------------------------------------------
# ACTIVEMQ
# ------------------------------------------------------
resource "aws_mq_broker" "activemq" {
  broker_name = "flower_co"

  engine_type        = "ActiveMQ"
  engine_version     = "5.15.9"
  host_instance_type = "mq.t2.micro"
  publicly_accessible = "true"

  user {
    username = "ExampleUser"
    password = "MindTheGapLongPassword"
  }
}