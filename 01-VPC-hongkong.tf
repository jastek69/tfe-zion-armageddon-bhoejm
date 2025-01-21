resource "aws_vpc" "HK_VPC" {              # VPC ID: aws_vpc.HK_VPC.id  
  provider         = aws.hongkong
  cidr_block       = "10.245.0.0/16"
  
  tags = {
    Name = "HK_VPC"
  }
}

resource "aws_subnet" "HK_SUBNET" {
  provider   = aws.hongkong
  vpc_id     = aws_vpc.HK_VPC.id 
  cidr_block = "10.245.0.0/24"
  availability_zone = "ap-east-1a"
  tags = {
    Name = "HK_SUBNET"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "hk-public-ap-east-1a" {
  provider                = aws.hongkong
  vpc_id                  = aws_vpc.HK_VPC.id
  cidr_block              = "10.245.1.0/24"
  availability_zone       = "ap-east-1a"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "hk-public-ap-east-1a"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "hk-public-ap-east-1b" {
  provider                = aws.hongkong
  vpc_id                  = aws_vpc.HK_VPC.id
  cidr_block              = "10.245.2.0/24"
  availability_zone       = "ap-east-1b"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "hk-public-ap-east-1b"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


#these are for private
resource "aws_subnet" "hk-private-ap-east-1a" {
  provider          = aws.hongkong
  vpc_id            = aws_vpc.HK_VPC.id
  cidr_block        = "10.245.11.0/24"
  availability_zone = "ap-east-1a"

  tags = {
    Name    = "hk-private-ap-east-1a"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "hk-private-ap-east-1b" {
  provider          = aws.hongkong
  vpc_id            = aws_vpc.HK_VPC.id
  cidr_block        = "10.245.12.0/24"
  availability_zone = "ap-east-1b"

  tags = {
    Name    = "hk-private-ap-east-1b"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_internet_gateway" "HK_IGW" {     # Internet Gateway ID: aws_internet_gateway.CA_IGW.id
  provider   = aws.hongkong
  vpc_id     = aws_vpc.HK_VPC.id

  tags = {
    Name = "HK_IGW"
  }
}


# Hong Kong Route Table
resource "aws_route_table" "HK_route_table" {   # Route Table ID: aws_route_table.CA_route_table.id
  provider = aws.hongkong
  vpc_id = aws_vpc.HK_VPC.id

  route {
    cidr_block = "10.240.1.0/24" # Route to TOKYO_VPC
    transit_gateway_id = aws_ec2_transit_gateway.hk-tgw.id
    }

  tags = {
    Name = "HK_ROUTE"
  }
}


# Route to backend services VPC via Transit Gateway Attachment
resource "aws_route" "HK_to_tokyo" {
  provider = aws.hongkong
  
  route_table_id         = aws_route_table.HK_route_table.id
  destination_cidr_block = "10.240.0.0/16"  # Replace with tokyo VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.hk_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hk_attachment]
}



/*

# Route to LONDON_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_london" {
  provider               = aws.hongkong
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.241.0.0/16"  # Replace with actual VPC2 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to SAO_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_sao" {
  provider               = aws.hongkong
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.243.0.0/16"  # Replace with actual VPC3 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}



# Route to HK_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_hongkong" {
  provider               = aws.hongkong
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.245.0.0/16"  # hongkong CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}

*/