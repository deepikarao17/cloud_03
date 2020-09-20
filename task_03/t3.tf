provider "aws" {
region = "ap-south-1"
profile = "xyz"
}

resource "aws_vpc" "create_vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "deepsvpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.create_vpc.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.create_vpc.id}"
  cidr_block = "192.168.2.0/24"
  #map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private"
  }
}
resource "aws_internet_gateway" "deepsgw" {
  vpc_id = "${aws_vpc.create_vpc.id}"

  tags = {
    Name = "deepsgw"
  }
}
resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.create_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.deepsgw.id}"
  }

  
  tags = {
    Name = "route_table"
  }
}


  

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.route_table.id
}



resource "aws_security_group" "sg_public" {
  name        = "sg_public"
  description = "sg_public"
  vpc_id      = "${aws_vpc.create_vpc.id}"

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 /* ingress {
    description = "sg_private"
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }*/
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg_public"
  }
}

resource "aws_security_group" "sg_private" {
  name        = "sg_private"
  description = "sg_private"
  vpc_id      = "${aws_vpc.create_vpc.id}"

  ingress {
    description = "sg_private"
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg_private"
  }
}

resource "aws_instance" "wordpress" {
  ami = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_public.id}"]
  key_name = "newkey"
 tags ={
    Name= "wordpress"
  }
depends_on = [
    aws_route_table_association.public_association,
  ]
}

resource "aws_instance" "mysql" {
  ami = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_private.id}"]
  key_name = "newkey"
 tags ={
    Name= "mysql"
  }
depends_on = [
    aws_route_table_association.public_association,
  ]
}

