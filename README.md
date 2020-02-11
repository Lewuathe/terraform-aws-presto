# terraform-aws-presto
Terraform module to create [Presto cluster](https://prestosql.io/). The cluster runs on top of AWS Fargate using docker image published by [Lewuathe](https://github.com/Lewuathe/docker-presto-cluster/)

# Usage

```terraform
module "presto" {
  source           = "github.com/Lewuathe/terraform-aws-presto"
  cluster_capacity = 2
}

output "alb_dns_name" {
  value = module.presto.alb_dns_name
}
```

You can connect to the Presto cluster through ALB.

```sh
$ ./presto-cli --server http://presto-XXXX.us-east-1.elb.amazonaws.com --catalog tpch --schema tiny
```

# Overview

![Overview](https://github.com/Lewuathe/terraform-aws-presto/blob/master/overview.png?raw=true)

# Variables

- `region`: AWS Region
- `vpc_cidr_block`: CIDR Block of the VPC where Presto cluster is running. There are two availability zones in the public/private subnets respectively. You can specify the CIDR block of these subnets by the following variables.
  - `public_0_cidr_block`
  - `public_1_cidr_block`
  - `private_0_cidr_block`
  - `private_1_cidr_block`
- `presto_version`: The tag of the docker image used in the cluster. See [Docker Hub](https://hub.docker.com/repository/docker/lewuathe/presto-base/tags) for available tags.
- `cluster_capacity`: The number of tasks for worker process

# Outputs

- `alb_dns_name`: The DNS name of the ALB connecting to coordinator.