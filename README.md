# AWS Infrastructure in a Box

This repository provides a SMB-sized infrastructure on AWS to run your 12-factor app.

Secure, but not ultimate secure -- for example "prod" and "staging" are logically separated, not isolated on the network (kinda). prod and staging run on the same subnet, but Security Groups limit their interactions.

I believe this architecture to be reasonably resilient for the purposes of an SMB.

## Usage

### aws.tf

```
```

### root.tf

```
data "aws_eip" "acmecorp_prod_eip" {
  tags = {
    Name = "ACME locked public ip"
  }
}

module "cluster" {
  source = "./modules/securecluster"
  name   = "acmecorp"

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  pinned_public_ip_subnet_eips = [
    data.aws_eip.acmecorp_prod_eip.id
  ]
}

module "clusterplane_prod" {
  depends_on = [module.cluster]

  source              = "./modules/clusterplane"
  securecluster       = module.cluster.securecluster
  securecluster_lists = module.cluster.securecluster_lists
  name                = "prod"
}
```
