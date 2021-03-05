resource "aws_subnet" "subnet" {
  count = length(var.availability_zones)

  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 10 + count.index)

  availability_zone = element(var.availability_zones, count.index)
  // availability_zone_id - (Optional) The AZ ID of the subnet.

  tags = {
    Name = "beryllium-${count.index}"
  }

  // these subnets use public ips and internet gateways
  // because it's cheaper than having a NAT gateway
  // per subnet we operate.
}
