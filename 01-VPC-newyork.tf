resource "aws_vpc" "NY_VPC" {
  provider = aws.newyork  
  cidr_block       = "10.246.0.0/16"

  tags = {
    Name = "NY_VPC"
  }
}

resource "aws_subnet" "NY_SUBNET" {
  provider = aws.newyork
  vpc_id     = aws_vpc.NY_VPC.id
  cidr_block = "10.246.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "NY_SUBNET"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "newyork-public-us-east-1a" {
  provider                = aws.newyork
  vpc_id                  = aws_vpc.NY_VPC.id
  cidr_block              = "10.246.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "newyork-public-us-east-1a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "newyork-public-us-east-1b" {
  provider                = aws.newyork
  vpc_id                  = aws_vpc.NY_VPC.id
  cidr_block              = "10.246.2.0/24"
  availability_zone       = "us-east-1b"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "newyork-public-us-east-1b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


#these are for private
resource "aws_subnet" "newyork-private-us-east-1a" {
  provider          = aws.newyork
  vpc_id            = aws_vpc.NY_VPC.id
  cidr_block        = "10.246.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name    = "newyork-private-us-east-1a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "newyork-private-us-east-1b" {
  provider          = aws.newyork
  vpc_id            = aws_vpc.NY_VPC.id
  cidr_block        = "10.246.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name    = "newyork-private-us-east-1b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_internet_gateway" "NY_IGW" {
  provider = aws.newyork  
  vpc_id     = aws_vpc.NY_VPC.id

  tags = {
    Name = "NY_IGW"
  }
}


# TOKYO Route Table
resource "aws_route_table" "NY_route_table" {        # Route Table ID: aws_route_table.LONDON_route_table.id
  provider = aws.newyork
  vpc_id = aws_vpc.NY_VPC.id

  route {
    cidr_block = "10.240.1.0/24" # Route to TOKYO_VPC
    transit_gateway_id = aws_ec2_transit_gateway.ny-tgw.id
    }

  tags = {
    Name = "NY_ROUTE"
  }
}

# Route to backend services VPC via Transit Gateway Attachment
resource "aws_route" "NY_to_tokyo" {
  provider = aws.newyork
  
  route_table_id         = aws_route_table.NY_route_table.id
  destination_cidr_block = "10.240.0.0/16"  # Replace with tokyo VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.ny_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.ny_attachment]
}




/*
resource "aws_route" "NY_to_sao" {
  provider = aws.newyork
  
  route_table_id         = aws_route_table.NY_route_table.id
  destination_cidr_block = "10.246.0.0/16"  # NY VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.ny_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.ny_attachment]
}
*/

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