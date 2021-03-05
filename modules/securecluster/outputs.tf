output "securecluster" {
  value = {
    "vpc_id"     = aws_vpc.vpc.id
    "cluster_id" = aws_ecs_cluster.cluster.id
  }
}

output "securecluster_lists" {
  value = {
    "availability_zones"           = var.availability_zones
    "pinned_public_ip_subnet_eips" = var.pinned_public_ip_subnet_eips
    "subnets"                      = aws_subnet.subnet.*.id
  }
}