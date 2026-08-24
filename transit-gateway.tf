# AWS Transit Gateway Inter-Region peering
/*
The following are best practices for your transit gateway design:

Use a separate subnet for each transit gateway VPC attachment. For each subnet, use a small CIDR, for example /28, so that you have more addresses for EC2 resources. When you use a separate subnet, you can configure the following:
Keep the inbound and outbound network ACLs associated with the transit gateway subnets open.
Depending on your traffic flow, you can apply network ACLs to your workload subnets.
Create one network ACL and associate it with all of the subnets that are associated with the transit gateway. Keep the network ACL open in both the inbound and outbound directions.
Associate the same VPC route table with all of the subnets that are associated with the transit gateway, unless your network design requires multiple VPC route tables (for example, a middle-box VPC that routes traffic through multiple NAT gateways).
Use Border Gateway Protocol (BGP) Site-to-Site VPN connections. If your customer gateway device or firewall for the connection supports multipath, enable the feature.
Enable route propagation for AWS Direct Connect gateway attachments and BGP Site-to-Site VPN attachments.
When migrating from VPC peering to use a transit gateway. An MTU size mismatch between VPC peering and the transit gateway might result in some packets dropping for asymmetric traffic. Update both VPCs at the same time to avoid jumbo packets dropping due to size mismatches.
You do not need additional transit gateways for high availability, because transit gateways are highly available by design.
Limit the number of transit gateway route tables unless your design requires multiple transit gateway route tables.
For redundancy, use a single transit gateway in each Region for disaster recovery.
For deployments with multiple transit gateways, we recommend that you use a unique Autonomous System Number (ASN) for each of your transit gateways. You can also use inter-Region peering. For more information, see Building a global network using AWS Transit Gateway Inter-Region peering.
*/


# TOKYO Transit Gateway - MAIN
resource "aws_ec2_transit_gateway" "tokyo-tgw" {
  description                    = "tg-tokyo-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Tokyo Transit Gateway"
  }
}

# LONDON Transit Gateway
resource "aws_ec2_transit_gateway" "london-tgw" {
  provider                       = aws.london
  description                    = "tg-london-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "London Transit Gateway"
  }
}

# Sao Paulo Transit Gateway
resource "aws_ec2_transit_gateway" "sao-tgw" {
  provider                       = aws.saopaulo
  description                    = "tg-sao-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Sao Paulo Transit Gateway"
  }
}

# California Transit Gateway
resource "aws_ec2_transit_gateway" "ca-tgw" {
  provider                       = aws.california
  description                    = "tg-ca-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "California Transit Gateway"
  }
}

# HONG KONG Transit Gateway
resource "aws_ec2_transit_gateway" "hk-tgw" {
  provider                       = aws.hongkong
  description                    = "tg-hk-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Hong Kong Transit Gateway"
  }
}


# NEW YORK Transit Gateway
resource "aws_ec2_transit_gateway" "ny-tgw" {
  provider                       = aws.newyork
  description                    = "tg-ny-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "New York Transit Gateway"
  }
}


# AUSTRALIA Transit Gateway
resource "aws_ec2_transit_gateway" "aus-tgw" {
  provider                       = aws.australia
  description                    = "tg-aus-database"
  auto_accept_shared_attachments = "enable"
  tags = {
    Name = "Australia Transit Gateway"
  }
}
# AWS Transit Gateway Inter-Region peering
# Transit Gateway Attachment
# Creating attachments for each VPC to Tokyo Transit Gateway
# Creating Peering Connection for inter-region peering connections to Tokyo Transit Gateway
################################################################################################

# TRANSIT GATEWAY ATTACHMENTS


# Attach TOKYO_VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo_attachment" {
  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.tokyo-tgw.id
  subnet_ids = [
    module.network_tokyo.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_tokyo.vpc_id

  # Optional tags for identification
  tags = {
    Name = "Tokyo VPC Attachment"
  }
}


# Attach LONDON VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "london_attachment" {
  provider = aws.london

  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.london-tgw.id
  subnet_ids = [
    module.network_london.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_london.vpc_id

  # Optional tags for identification
  tags = {
    Name = "London VPC Attachment"
  }
}

# Attach Sao Paulo VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "sao_attachment" {
  provider = aws.saopaulo

  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.sao-tgw.id
  subnet_ids = [
    module.network_saopaulo.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_saopaulo.vpc_id

  # Optional tags for identification
  tags = {
    Name = "Sao Paulo VPC Attachment"
  }
}


# Attach California VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "ca_attachment" {
  provider = aws.california

  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.ca-tgw.id
  subnet_ids = [
    module.network_california.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_california.vpc_id

  # Optional tags for identification
  tags = {
    Name = "California VPC Attachment"
  }
}


# Attach Hong Kong VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "hk_attachment" {
  provider = aws.hongkong

  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.hk-tgw.id
  subnet_ids = [
    module.network_hongkong.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_hongkong.vpc_id

  # Optional tags for identification
  tags = {
    Name = "Hong Kong VPC Attachment"
  }
}



# Attach New York VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "ny_attachment" {
  provider = aws.newyork

  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.ny-tgw.id
  subnet_ids = [
    module.network_newyork.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_newyork.vpc_id

  # Optional tags for identification
  tags = {
    Name = "New York VPC Attachment"
  }
}


# Attach Australia VPC to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "aus_attachment" {
  provider = aws.australia

  # ID of the Transit Gateway
  transit_gateway_id = aws_ec2_transit_gateway.aus-tgw.id
  subnet_ids = [
    module.network_australia.tgw_subnet_id # Reference the created subnet ID
  ]
  # VPC ID to be attached
  vpc_id = module.network_australia.vpc_id

  # Optional tags for identification
  tags = {
    Name = "Australia VPC Attachment"
  }
}



###############################################################################################
# PEERING ATTACHMENTS
# 1 - Resource - Create the inter-region Peering Attachment from Tokyo to London.
# The peer_transit_gateway_id must reference a Transit Gateway from a different region,
# and the peer_region must align with the region of the peer_transit_gateway_id.
# tgw_tokyo_source_peering: peer_region = "eu-west-2" should match the region of the london-tgw.
# 
# 2 - Data - peering attachment data for the London Transit Gateway.
# This will create two peerings: one for Tokyo (Creator)
#
# 3 - Accepter - and one for London (Acceptor).
###############################################################################################


# Tokyo VPC to London VPC
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_tokyo_source_peering" {
  transit_gateway_id      = aws_ec2_transit_gateway.tokyo-tgw.id  # TOKYO Transit Gateway ID
  peer_transit_gateway_id = aws_ec2_transit_gateway.london-tgw.id # London Transit Gateway ID to Peer WITH
  peer_region             = "eu-west-2"                           # London region to Peer WITH  

  tags = {
    Name = "Tokyo London Peering Attachment"
    Side = "Creator"
  }
}

# Transit Gateway 2's peering request needs to be accepted.
# So, we fetch the Peering Attachment that is created for the Gateway 2.
data "aws_ec2_transit_gateway_peering_attachment" "london_accepter_peering_data" {
  provider   = aws.london
  depends_on = [aws_ec2_transit_gateway_peering_attachment.tgw_tokyo_source_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.london-tgw.id]
  }
}

# Accept the Attachment Peering request.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "london_accepter" {
  provider                      = aws.london
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.london_accepter_peering_data.id
  tags = {
    Name = "terraform-london-tgw-peering-accepter"
    Side = "Acceptor"
  }
}


#######################################################################################################
# SAO PAULO TO TOKYO PEERING
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_tokyo_sao_source_peering" {
  # provider = aws.saopaulo
  transit_gateway_id      = aws_ec2_transit_gateway.tokyo-tgw.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.sao-tgw.id # Sao Paulo Transit Gateway ID to Peer WITH
  peer_region             = "sa-east-1"                        # Sao Paulo region to Peer WITH  

  tags = {
    Name = "Tokyo Sao Peering Attachment"
    Side = "Creator"
  }
}


# Transit Gateway 2's peering request needs to be accepted.
# So, we fetch the Peering Attachment that is created for the Gateway 3 - Sao Paulo.
data "aws_ec2_transit_gateway_peering_attachment" "sao_accepter_peering_data" {
  provider   = aws.saopaulo
  depends_on = [aws_ec2_transit_gateway_peering_attachment.tgw_tokyo_sao_source_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.sao-tgw.id]
  }
}

# Accept the Attachment Peering request.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "sao_accepter" {
  provider                      = aws.saopaulo
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.sao_accepter_peering_data.id
  tags = {
    Name = "terraform-sao-tgw-peering-accepter"
    Side = "Acceptor"
  }
}


###############################################################################################################
# HONG KONG TO TOKYO PEERING
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_tokyo_hk_source_peering" {

  transit_gateway_id      = aws_ec2_transit_gateway.tokyo-tgw.id # Tokyo TGW ID
  peer_transit_gateway_id = aws_ec2_transit_gateway.hk-tgw.id    # Hong Kong Transit Gateway ID to Peer WITH
  peer_region             = "ap-east-1"                          # Hong Kong region to Peer WITH  

  tags = {
    Name = "Tokyo Hong Kong Peering Attachment"
    Side = "Creator"
  }
}


# Transit Gateway Hong Kong peering request needs to be accepted.
# So, we fetch the Peering Attachment that is created for the Gateway 3 - Sao Paulo.
data "aws_ec2_transit_gateway_peering_attachment" "hk_accepter_peering_data" {
  provider   = aws.hongkong
  depends_on = [aws_ec2_transit_gateway_peering_attachment.tgw_tokyo_hk_source_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.hk-tgw.id]
  }
}

# Accept the Attachment Peering request.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "hk_accepter" {
  provider                      = aws.hongkong
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.hk_accepter_peering_data.id
  tags = {
    Name = "terraform-hk-tgw-peering-accepter"
    Side = "Acceptor"
  }
}


#################################################################################################################
# NEW YORK TO TOKYO PEERING
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_tokyo_ny_source_peering" {

  transit_gateway_id      = aws_ec2_transit_gateway.tokyo-tgw.id # Tokyo TGW ID
  peer_transit_gateway_id = aws_ec2_transit_gateway.ny-tgw.id    # Peer/New York Transit Gateway ID to Peer WITH
  peer_region             = "us-east-1"                          # New York region to Peer WITH  

  tags = {
    Name = "Tokyo New York Peering Attachment"
    Side = "Creator"
  }
}


# Transit Gateway New York peering request needs to be accepted.
# Fetch the Peering Attachment that is created for the Gateway 5 New York.
data "aws_ec2_transit_gateway_peering_attachment" "ny_accepter_peering_data" {
  provider   = aws.newyork
  depends_on = [aws_ec2_transit_gateway_peering_attachment.tgw_tokyo_ny_source_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.ny-tgw.id]
  }
}


# Accept the Attachment Peering request.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "ny_accepter" {
  provider                      = aws.newyork
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.ny_accepter_peering_data.id
  tags = {
    Name = "terraform-ny-tgw-peering-accepter"
    Side = "Acceptor"
  }
}


###############################################################################################################
# AUSTRALIA TO TOKYO PEERING
resource "aws_ec2_transit_gateway_peering_attachment" "tgw_tokyo_aus_source_peering" {

  transit_gateway_id      = aws_ec2_transit_gateway.tokyo-tgw.id # Tokyo TGW ID
  peer_transit_gateway_id = aws_ec2_transit_gateway.aus-tgw.id   # Peer/Australia Transit Gateway ID to Peer WITH
  peer_region             = "ap-southeast-2"                     # Australia region to Peer WITH  

  tags = {
    Name = "Tokyo Australia Peering Attachment"
    Side = "Creator"
  }
}

# Transit Gateway Australia peering request needs to be accepted.
# Fetch the Peering Attachment that is created for the Gateway 6 Australia.
data "aws_ec2_transit_gateway_peering_attachment" "aus_accepter_peering_data" {
  provider   = aws.australia
  depends_on = [aws_ec2_transit_gateway_peering_attachment.tgw_tokyo_aus_source_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.aus-tgw.id]
  }
}


# Accept the Attachment Peering request.
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "aus_accepter" {
  provider                      = aws.australia
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.aus_accepter_peering_data.id
  tags = {
    Name = "terraform-aus-tgw-peering-accepter"
    Side = "Acceptor"
  }
}
/* TRANSIT GATEWAY ROUTE ATTACHMENT */
# Route to LONDON_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_london" {
  route_table_id         = module.network_tokyo.route_table_id
  destination_cidr_block = "10.241.0.0/16" # Replace with actual VPC2 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to SAO_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_sao" {
  route_table_id         = module.network_tokyo.route_table_id
  destination_cidr_block = "10.243.0.0/16" # Replace with actual VPC3 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to CA_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_california" {
  route_table_id         = module.network_tokyo.route_table_id
  destination_cidr_block = "10.244.0.0/16" # California CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to Hong Kong VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_hongkong" {
  route_table_id         = module.network_tokyo.route_table_id
  destination_cidr_block = "10.245.0.0/16" # Hong Kong CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to NY_VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_ny" {
  route_table_id         = module.network_tokyo.route_table_id
  destination_cidr_block = "10.246.0.0/16" # New York CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}


# Route to Australia VPC via Transit Gateway Attachment
resource "aws_route" "TOKYO_to_australia" {
  route_table_id         = module.network_tokyo.route_table_id
  destination_cidr_block = "10.247.0.0/16" # Australia CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tokyo_attachment]
}

# Spoke VPC routes to Tokyo hub over regional Transit Gateways

resource "aws_route" "AUS_to_tokyo" {
  provider               = aws.australia
  route_table_id         = module.network_australia.route_table_id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.aus_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.aus_attachment]
}

resource "aws_route" "CA_to_tokyo" {
  provider               = aws.california
  route_table_id         = module.network_california.route_table_id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.ca_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.ca_attachment]
}

resource "aws_route" "HK_to_tokyo" {
  provider               = aws.hongkong
  route_table_id         = module.network_hongkong.route_table_id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.hk_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.hk_attachment]
}

resource "aws_route" "LONDON_to_tokyo" {
  provider               = aws.london
  route_table_id         = module.network_london.route_table_id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.london_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.london_attachment]
}

resource "aws_route" "NY_to_tokyo" {
  provider               = aws.newyork
  route_table_id         = module.network_newyork.route_table_id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.ny_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.ny_attachment]
}

resource "aws_route" "SAO_to_tokyo" {
  provider               = aws.saopaulo
  route_table_id         = module.network_saopaulo.route_table_id
  destination_cidr_block = local.tokyo_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.sao_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.sao_attachment]
}

resource "aws_route" "SAO_to_london" {
  provider               = aws.saopaulo
  route_table_id         = module.network_saopaulo.route_table_id
  destination_cidr_block = local.sites.london.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.sao_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.sao_attachment]
}

resource "aws_route" "LONDON_to_sao" {
  provider               = aws.london
  route_table_id         = module.network_london.route_table_id
  destination_cidr_block = local.sites.saopaulo.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.london_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.london_attachment]
}
