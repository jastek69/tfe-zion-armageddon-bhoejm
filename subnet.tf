#These are   for  public

/*
# LONDON Subnets
resource "aws_subnet" "public-eu-west-2a" {
  provider                = aws.london
  vpc_id                  = aws_vpc.LONDON_VPC.id
  cidr_block              = "10.241.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-eu-west-2a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}



resource "aws_subnet" "public-eu-west-2b" {
  provider                = aws.london
  vpc_id                  = aws_vpc.LONDON_VPC.id
  cidr_block              = "10.241.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-eu-west-2b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}

#these are for private
resource "aws_subnet" "private-eu-west-2a" {
  provider          = aws.london
  vpc_id            = aws_vpc.LONDON_VPC.id
  cidr_block        = "10.241.11.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name    = "private-eu-west-2a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}



resource "aws_subnet" "private-eu-west-2b" {
  provider          = aws.london
  vpc_id            = aws_vpc.LONDON_VPC.id
  cidr_block        = "10.241.12.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name    = "private-eu-west-2b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}
*/



#SAO PAULO Subnets
#These are   for  public

/*
resource "aws_subnet" "public-sa-east-1a" {
  provider                = aws.saopaulo
  vpc_id                  = aws_vpc.SAO_VPC.id
  cidr_block              = "10.243.1.0/24"
  availability_zone       = "sa-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-sa-east-1a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "public-sa-east-1b" {
  provider                = aws.saopaulo
  vpc_id                  = aws_vpc.SAO_VPC.id
  cidr_block              = "10.243.2.0/24"
  availability_zone       = "sa-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-sa-east-1b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}

#these are for private
resource "aws_subnet" "private-sa-east-1a" {
  provider          = aws.saopaulo
  vpc_id            = aws_vpc.SAO_VPC.id
  cidr_block        = "10.243.11.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name    = "private-sa-east-1a"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}


resource "aws_subnet" "private-sa-east-1b" {
  provider          = aws.saopaulo
  vpc_id            = aws_vpc.SAO_VPC.id
  cidr_block        = "10.243.12.0/24"
  availability_zone = "sa-east-1b"

  tags = {
    Name    = "private-sa-east-1b"
    Service = "application1"
    Owner   = "Blackneto"
    Planet  = "Taa"
  }
}
*/