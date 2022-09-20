# Creating an S3 Bucket
resource "aws_s3_bucket" "ProjectBucket" {
  bucket               = var.bucket_name
  
  tags = {
    Name = "brandonhprojectbucket"
  }
}

# Creating a VPC
resource "aws_vpc" "mainVPC" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "ProjectVPC"
  }
}

# Creating a Public and Private Subnet
resource "aws_subnet" "PublicSubnet" {
  vpc_id                  = aws_vpc.mainVPC.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.region
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicProjectSubnet"
  }
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id                  = aws_vpc.mainVPC.id
  cidr_block              = var.private_cidr
  availability_zone       = var.region
  map_public_ip_on_launch = false

  tags = {
    Name = "PrivateProjectSubnet"
  }
}

# Creating an Internet Gateway For Public Access
resource "aws_internet_gateway" "ProjectIGW" {
  vpc_id = aws_vpc.mainVPC.id

  tags = {
    Name = "ProjectIG"
  }
}

# Creating a Public and Private Route Table
resource "aws_route_table" "PublicRoute" {
  vpc_id = aws_vpc.mainVPC.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ProjectIGW.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "PrivateRoute" {
  vpc_id = aws_vpc.mainVPC.id

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Creating the Proper Associations for Route Tables

resource "aws_route_table_association" "PublicRouteAssociations" {
  route_table_id = aws_route_table.PublicRoute.id
  subnet_id      = aws_subnet.PublicSubnet.id
}

resource "aws_route_table_association" "PrivateRouteAssociations" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.PrivateRoute.id
}

# Creating EC2 Instances 
resource "aws_instance" "AnsibleMaster" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.Allow_SSH.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.PublicSubnet.id

  # Providing existing keypair that will be used to SSH in the instance
  key_name               = "Brandon"
  # Upon the Instance being created, Executing Commands to Install Ansible
  user_data = "${file("Install_Ansible.sh")}"
  
  # Alternative way to run Commands without a scripting file
 /*provisioner "remote-exec" {
    inline = [
      "sudo -i",
      "yum install epel-release -y",
      "yum update",
      "yum install ansible -y",
    ]
  }*/

  tags = {
    Name = "AnsibleMaster"
  }
}

resource "aws_instance" "AnsibleSlaves" {
  ami                         = var.ami
  instance_type               = var.instance_type
  count                       = 3 
  vpc_security_group_ids      = [aws_security_group.Allow_SSH.id]
  key_name                    = "Brandon"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.PublicSubnet.id

  tags = {
    Name = "AnsibleSlave-${count.index+1}"
  }
}

# Creating a Security Group to Allow Inbound/Outbound SSH and ICMP Connections for Instances
resource "aws_security_group" "Allow_SSH" {
  name        = "allow_ssh1"
  description = "Allow SSH inbound traffic and ICMP inbound/outbound"
  vpc_id      = aws_vpc.mainVPC.id
  lifecycle { create_before_destroy = true }

  ingress {
    description      = "Allowing inbound SSH Traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allowing inbound ICMP Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
  } 

  egress {
    description      = "Allowing outbound SSH Traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allowing outbound ICMP Traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
  } 

  tags = {
    Name = "Allow_SSH"
  }
}
