resource "aws_subnet" "subnet_pinned_public_ip" {
  count = min(length(var.pinned_public_ip_subnet_eips), length(var.availability_zones))

  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 20 + count.index)

  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "beryllium-${count.index}-pinned"
  }
}

resource "aws_route_table" "subnet_pinned_public_ip" {
  count = min(length(var.pinned_public_ip_subnet_eips), length(var.availability_zones))

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw[count.index].id
  }

  tags = {
    Name = "beryllium via pinned nat"
  }
}

resource "aws_route_table_association" "subnet_pinned_public_ip" {
  count = min(length(var.pinned_public_ip_subnet_eips), length(var.availability_zones))

  subnet_id      = aws_subnet.subnet_pinned_public_ip[count.index].id
  route_table_id = aws_route_table.subnet_pinned_public_ip[count.index].id
}

resource "aws_nat_gateway" "gw" {
  depends_on = [aws_internet_gateway.igw]
  // depends_on igw
  count = min(length(var.pinned_public_ip_subnet_eips), length(var.availability_zones))

  subnet_id = aws_subnet.subnet_pinned_public_ip[count.index].id

  allocation_id = element(var.pinned_public_ip_subnet_eips, count.index)

  tags = {
    Name = "beryllium-${count.index}-pinned-gw"
  }
}
