output "vpc_id" {
  value = aws_vpc.this.id
}

output "tgw_subnet_id" {
  value = aws_subnet.tgw.id
}

output "public_subnet_ids" {
  value = [for az in sort(keys(aws_subnet.public)) : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  value = [for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].id]
}

output "database_subnet_ids" {
  description = "Private subnet IDs tagged for syslog or database (Tokyo storage tier)."
  value = [
    for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].id
    if contains(["syslog", "database"], aws_subnet.private[key].tags["Service"])
  ]
}

output "route_table_id" {
  value = aws_route_table.main.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}
