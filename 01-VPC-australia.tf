resource "aws_vpc" "AUS_VPC" {
  provider = aws.australia  
  cidr_block       = "10.247.0.0/16"

  tags = {
    Name = "AUS_VPC"
  }
}

resource "aws_subnet" "AUS_SUBNET" {
  provider = aws.australia
  vpc_id     = aws_vpc.AUS_VPC.id
  cidr_block = "10.247.0.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "AUS_SUBNET"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "australia-public-ap-southeast-2a" {
  provider                = aws.australia
  vpc_id                  = aws_vpc.AUS_VPC.id
  cidr_block              = "10.247.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "australia-public-ap-southeast-2a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "australia-public-ap-southeast-2b" {
  provider                = aws.australia
  vpc_id                  = aws_vpc.AUS_VPC.id
  cidr_block              = "10.247.2.0/24"
  availability_zone       = "ap-southeast-2b"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "australia-public-ap-southeast-2b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


#these are for private
resource "aws_subnet" "australia-private-ap-southeast-2a" {
  provider          = aws.australia
  vpc_id            = aws_vpc.AUS_VPC.id
  cidr_block        = "10.247.11.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name    = "australia-private-ap-southeast-2a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "australia-private-ap-southeast-2b" {
  provider          = aws.australia
  vpc_id            = aws_vpc.AUS_VPC.id
  cidr_block        = "10.247.12.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name    = "australia-private-ap-southeast-2b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_internet_gateway" "AUS_IGW" {
  provider = aws.australia  
  vpc_id     = aws_vpc.AUS_VPC.id

  tags = {
    Name = "AUS_IGW"
  }
}


# TOKYO Route Table
resource "aws_route_table" "AUS_route_table" {        # Route Table ID: aws_route_table.LONDON_route_table.id
  provider = aws.australia
  vpc_id = aws_vpc.AUS_VPC.id

  route {
    cidr_block = "10.240.1.0/24" # Route to TOKYO_VPC
    transit_gateway_id = aws_ec2_transit_gateway.aus-tgw.id
    }

  tags = {
    Name = "AUS_ROUTE"
  }
}

# Route to backend services VPC via Transit Gateway Attachment
resource "aws_route" "AUS_to_tokyo" {
  provider = aws.australia
  
  route_table_id         = aws_route_table.AUS_route_table.id
  destination_cidr_block = "10.240.0.0/16"  # Tokyo VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.aus_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.aus_attachment]
}




/*
resource "aws_route" "NY_to_sao" {
  provider = aws.australia
  
  route_table_id         = aws_route_table.AUS_route_table.id
  destination_cidr_block = "10.247.0.0/16"  # NY VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.aus_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.aus_attachment]
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