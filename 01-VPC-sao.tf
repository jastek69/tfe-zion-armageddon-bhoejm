resource "aws_vpc" "SAO_VPC" {
  provider = aws.saopaulo  
  cidr_block       = "10.243.0.0/16"  

  tags = {
    Name = "SAO_VPC"
  }
}

resource "aws_subnet" "SAO_SUBNET" {
  provider = aws.saopaulo
  
  vpc_id     = aws_vpc.SAO_VPC.id
  cidr_block = "10.243.0.0/24"
  availability_zone = "sa-east-1a"
  #map_public_ip_on_launch = true
  tags = {
    Name = "SAO_SUBNET"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "sao-public-sa-east-1a" {
  provider                = aws.saopaulo
  vpc_id                  = aws_vpc.SAO_VPC.id
  cidr_block              = "10.243.1.0/24"
  availability_zone       = "sa-east-1a"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "sao-public-sa-east-1a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "sao-public-sa-east-1b" {
  provider                = aws.saopaulo
  vpc_id                  = aws_vpc.SAO_VPC.id
  cidr_block              = "10.243.2.0/24"
  availability_zone       = "sa-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "sao-public-sa-east-1b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}

#these are for private
resource "aws_subnet" "sao-private-sa-east-1a" {
  provider          = aws.saopaulo
  vpc_id            = aws_vpc.SAO_VPC.id
  cidr_block        = "10.243.11.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name    = "sao-private-sa-east-1a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "sao-private-sa-east-1b" {
  provider          = aws.saopaulo
  vpc_id            = aws_vpc.SAO_VPC.id
  cidr_block        = "10.243.12.0/24"
  availability_zone = "sa-east-1b"

  tags = {
    Name    = "sao-private-sa-east-1b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_internet_gateway" "SAO_IGW" {
  provider   = aws.saopaulo  
  vpc_id     = aws_vpc.SAO_VPC.id

  tags = {
    Name = "SAO_IGW"
  }
}


# Sao Paulo Route Table
resource "aws_route_table" "SAO_route_table" {        # Route Table ID: aws_route_table.SAO_route_table.id
  provider = aws.saopaulo
  vpc_id = aws_vpc.SAO_VPC.id

  route {
    cidr_block = "10.240.1.0/24" # Route to TOKYO_VPC
    transit_gateway_id = aws_ec2_transit_gateway.sao-tgw.id
    }

  tags = {
    Name = "SAO_ROUTE"
  }
}


# Route to backend services VPC via Transit Gateway Attachment
resource "aws_route" "SAO_to_london" {
  provider = aws.saopaulo
  
  route_table_id         = aws_route_table.SAO_route_table.id
  destination_cidr_block = "10.241.0.0/16"  # Replace with actual london VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.sao_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.sao_attachment]
}

resource "aws_route" "SAO_to_tokyo" {
  provider = aws.saopaulo
  
  route_table_id         = aws_route_table.SAO_route_table.id
  destination_cidr_block = "10.240.0.0/16"  # Replace with actual web_app VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.sao_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.sao_attachment]
}
