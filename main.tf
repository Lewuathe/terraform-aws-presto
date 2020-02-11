provider "aws" {
  region = var.region
}

################
# VPC
################
resource "aws_vpc" "presto" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "presto"
  }
}

#################
# Public Subnet #
#################
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.presto.id
  cidr_block              = var.public_0_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Presto Public Subnet 0"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.presto.id
  cidr_block              = var.public_1_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1c"

  tags = {
    Name = "Presto Public Subnet 1"
  }
}

resource "aws_internet_gateway" "public_gw" {
  vpc_id = aws_vpc.presto.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.presto.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.public_gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

##################
# Private Subnet #
##################
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.presto.id
  cidr_block              = var.private_0_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Presto Private Subnet 0"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.presto.id
  cidr_block              = var.private_1_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1c"

  tags = {
    Name = "Presto Private Subnet 1"
  }
}

resource "aws_eip" "nat_gateway_0" {
  vpc        = true
  depends_on = [aws_internet_gateway.public_gw]
}

resource "aws_eip" "nat_gateway_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.public_gw]
}

resource "aws_nat_gateway" "private_gw_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.public_gw]
}

resource "aws_nat_gateway" "private_gw_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.public_gw]
}

resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.presto.id
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.presto.id
}

resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.private_gw_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.private_gw_1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

###################
# Security Groups #
###################
resource "aws_security_group" "alb" {
  name   = "presto-alb"
  vpc_id = aws_vpc.presto.id

  tags = {
    Name = "presto-alb"
  }
}

resource "aws_security_group_rule" "alb_ingress_80" {
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_443" {
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "coordinator" {
  name   = "presto-coordinator"
  vpc_id = aws_vpc.presto.id

  tags = {
    Name = "presto-coordinator"
  }
}

resource "aws_security_group_rule" "coordinator_ingress" {
  type              = "ingress"
  from_port         = "8080"
  to_port           = "8080"
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.coordinator.id
}

resource "aws_security_group_rule" "coordinator_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.coordinator.id
}

resource "aws_security_group" "worker" {
  name   = "presto-worker"
  vpc_id = aws_vpc.presto.id

  tags = {
    Name = "presto-worker"
  }
}

resource "aws_security_group_rule" "worker_ingress" {
  type              = "ingress"
  from_port         = "8080"
  to_port           = "8081"
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
}

#######
# ALB #
#######
resource "aws_lb" "presto_alb" {
  name                       = "presto"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  security_groups = [
    aws_security_group.alb.id
  ]
}

resource "aws_lb_target_group" "presto_target_group" {
  name                 = "presto-coordinator-tg"
  vpc_id               = aws_vpc.presto.id
  target_type          = "ip"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 300
  slow_start           = 60

  health_check {
    path                = "/v1/info"
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.presto_alb]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.presto_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.presto_target_group.arn
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.presto_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.presto_target_group.arn
#   }
# }


#######
# ECS #
#######
resource "aws_ecs_cluster" "presto" {
  name = "presto"
}

data "template_file" "coordinator_container" {
  template = file("${path.module}/coordinator-container.json.template")

  vars = {
    presto_version = var.presto_version
  }
}

resource "aws_ecs_task_definition" "presto_coordinator" {
  family                   = "presto-coordinator"
  cpu                      = "2048"
  memory                   = "4096"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.coordinator_container.rendered
}

data "template_file" "worker_container" {
  template = file("${path.module}/worker-container.json.template")

  vars = {
    presto_version = var.presto_version
    discovery_uri  = aws_lb.presto_alb.dns_name
  }
}

resource "aws_ecs_task_definition" "presto_worker" {
  family                   = "presto-worker"
  cpu                      = "2048"
  memory                   = "4096"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.worker_container.rendered
}

resource "aws_ecs_service" "presto_coordinator" {
  name                              = "presto-coordinator"
  cluster                           = aws_ecs_cluster.presto.arn
  task_definition                   = aws_ecs_task_definition.presto_coordinator.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.coordinator.id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.presto_target_group.arn
    container_name   = "presto-coordinator"
    container_port   = "8080"
  }
}

resource "aws_ecs_service" "presto_worker" {
  name            = "presto-worker"
  cluster         = aws_ecs_cluster.presto.arn
  task_definition = aws_ecs_task_definition.presto_worker.arn
  desired_count   = var.cluster_capacity
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.worker.id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }
}