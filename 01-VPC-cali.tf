resource "aws_vpc" "CA_VPC" {              # VPC ID: aws_vpc.CA_VPC.id  
  provider         = aws.california
  cidr_block       = "10.244.0.0/16"
  
  tags = {
    Name = "CA_VPC"
  }
}

resource "aws_subnet" "CA_SUBNET" {
  provider   = aws.california
  vpc_id     = aws_vpc.CA_VPC.id
  cidr_block = "10.244.0.0/24"
  availability_zone = "us-west-1a"
  tags = {
    Name = "CA_SUBNET"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "cali-public-us-west-1a" {
  provider                = aws.california
  vpc_id                  = aws_vpc.CA_VPC.id
  cidr_block              = "10.244.1.0/24"
  availability_zone       = "us-west-1a"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "cali-public-us-west-1a"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "cali-public-us-west-1b" {
  provider                = aws.california
  vpc_id                  = aws_vpc.CA_VPC.id
  cidr_block              = "10.244.2.0/24"
  availability_zone       = "us-west-1b"
  #map_public_ip_on_launch = true

  tags = {
    Name    = "cali-public-us-west-1b"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


#these are for private
resource "aws_subnet" "cali-private-us-west-1a" {
  provider          = aws.california
  vpc_id            = aws_vpc.CA_VPC.id
  cidr_block        = "10.244.11.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name    = "cali-private-us-west-1a"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "cali-private-us-west-1b" {
  provider          = aws.california
  vpc_id            = aws_vpc.CA_VPC.id
  cidr_block        = "10.244.12.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name    = "cali-private-us-west-1b"
    Service = "application1"
    Owner   = "Balactus"
    Planet  = "Taa"
  }
}


resource "aws_internet_gateway" "CA_IGW" {     # Internet Gateway ID: aws_internet_gateway.CA_IGW.id
  provider   = aws.california
  vpc_id     = aws_vpc.CA_VPC.id

  tags = {
    Name = "CA_IGW"
  }
}


# CALIFORNIA Route Table
resource "aws_route_table" "CA_route_table" {   # Route Table ID: aws_route_table.CA_route_table.id
  provider = aws.california
  vpc_id = aws_vpc.CA_VPC.id

  route {
    cidr_block = "10.240.1.0/24" # Route to TOKYO_VPC
    transit_gateway_id = aws_ec2_transit_gateway.ca-tgw.id
    }

  tags = {
    Name = "CA_ROUTE"
  }
}


# Route to backend services VPC via Transit Gateway Attachment
resource "aws_route" "CA_to_tokyo" {
  provider = aws.california
  
  route_table_id         = aws_route_table.CA_route_table.id
  destination_cidr_block = "10.240.0.0/16"  # Replace with tokyo VPC CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.ca_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.ca_attachment]
}



/*

# Route to LONDON_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_london" {
  provider               = aws.california
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.241.0.0/16"  # Replace with actual VPC2 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to SAO_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_sao" {
  provider               = aws.california
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.243.0.0/16"  # Replace with actual VPC3 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}



# Route to CA_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_california" {
  provider               = aws.california
  route_table_id         = aws_route_table.TOKYO_route_table.id
  destination_cidr_block = "10.244.0.0/16"  # California CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}

*/