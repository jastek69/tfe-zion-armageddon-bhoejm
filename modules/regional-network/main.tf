resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name     = var.vpc_name
    Planet   = var.planet
    location = var.location
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_subnet" "tgw" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.tgw_subnet.cidr
  availability_zone = var.tgw_subnet.az

  tags = merge(var.common_tags, {
    Name    = "${var.prefix}-tgw-subnet"
    Service = "transit-gateway"
  })
}

resource "aws_subnet" "public" {
  for_each = { for subnet in var.public_subnets : subnet.az => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.map_public_ip

  tags = merge(var.common_tags, {
    Name    = "${var.prefix}-public-${each.value.az}"
    Service = "application1"
  })
}

resource "aws_subnet" "private" {
  for_each = { for subnet in var.private_subnets : "${subnet.az}-${subnet.cidr}" => subnet }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name    = "${var.prefix}-private-${each.value.az}"
    Service = each.value.service
  })
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-route-table"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "tgw" {
  subnet_id      = aws_subnet.tgw.id
  route_table_id = aws_route_table.main.id
}
