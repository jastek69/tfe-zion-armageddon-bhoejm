resource "aws_vpc" "LONDON_VPC" {
  provider = aws.london  
  cidr_block       = "10.241.0.0/16"  

  tags = {
    Name = "LONDON_VPC"
  }
}

resource "aws_subnet" "LONDON_SUBNET" {
  provider = aws.london
  vpc_id     = aws_vpc.LONDON_VPC.id
  cidr_block = "10.241.0.0/24"
  availability_zone = "eu-west-2a"
  tags = {
    Name = "LONDON_SUBNET"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "london-public-eu-west-2a" {
  provider                = aws.london
  vpc_id                  = aws_vpc.LONDON_VPC.id
  cidr_block              = "10.241.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "london-public-eu-west-2a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "london-public-eu-west-2b" {
  provider                = aws.london
  vpc_id                  = aws_vpc.LONDON_VPC.id
  cidr_block              = "10.241.2.0/24"
  availability_zone       = "eu-west-2b"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "london-public-eu-west-2b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


#these are for private
resource "aws_subnet" "london-private-eu-west-2a" {
  provider          = aws.london
  vpc_id            = aws_vpc.LONDON_VPC.id
  cidr_block        = "10.241.11.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name    = "london-private-eu-west-2a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "london-private-eu-west-2b" {
  provider          = aws.london
  vpc_id            = aws_vpc.LONDON_VPC.id
  cidr_block        = "10.241.12.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name    = "london-private-eu-west-2b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_internet_gateway" "LONDON_IGW" {
  provider = aws.london  
  vpc_id     = aws_vpc.LONDON_VPC.id

  tags = {
    Name = "LONDON_IGW"
  }
}


# TOKYO Route Table
resource "aws_route_table" "LONDON_route_table" {        # Route Table ID: aws_route_table.LONDON_route_table.id
  provider = aws.london
  vpc_id = aws_vpc.LONDON_VPC.id

  route {
    cidr_block = "10.240.1.0/24" # Route to TOKYO_VPC
    transit_gateway_id = aws_ec2_transit_gateway.london-tgw.id
    }

  tags = {
    Name = "LONDON_ROUTE"
  }
}


resource "aws_route" "LONDON_to_tokyo" {
  provider = aws.london
  
  route_table_id         = aws_route_table.LONDON_route_table.id
  destination_cidr_block = "10.240.0.0/16"  # Replace with tokyo VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.london_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.london_attachment]
}

resource "aws_route" "LONDON_to_sao" {
  provider = aws.london
  
  route_table_id         = aws_route_table.LONDON_route_table.id
  destination_cidr_block = "10.242.0.0/16"  # Replace with actual Sao Paulo VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.london_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.london_attachment]
}


/*

# Route to CA_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_california" {
  provider               = aws.california
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.244.0.0/16"  # California CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}

*/