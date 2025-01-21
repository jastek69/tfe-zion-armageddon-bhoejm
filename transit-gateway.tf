
resource "aws_ec2_transit_gateway" "tokyo-tgw" {
  description = "tg-tokyo-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Tokyo Transit Gateway"
  }
}


resource "aws_ec2_transit_gateway" "london-tgw" {
  provider = aws.london
  description = "tg-london-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "London Transit Gateway"
  }
}


resource "aws_ec2_transit_gateway" "sao-tgw" {
  provider = aws.saopaulo
  description = "tg-sao-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Sao Paulo Transit Gateway"
  }
}


resource "aws_ec2_transit_gateway" "ca-tgw" {
  provider = aws.california
  description = "tg-ca-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "California Transit Gateway"
  }
}

# HONG KONG Transit Gateway
resource "aws_ec2_transit_gateway" "hk-tgw" {
  provider = aws.hongkong
  description = "tg-hk-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Hong Kong Transit Gateway"
  }
}


# NEW YORK Transit Gateway
resource "aws_ec2_transit_gateway" "ny-tgw" {
  provider = aws.newyork
  description = "tg-ny-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "New York Transit Gateway"
  }
}


# AUSTRALIA Transit Gateway
resource "aws_ec2_transit_gateway" "aus-tgw" {
  provider = aws.australia
  description = "tg-aus-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Australia Transit Gateway"
  }
}
