variable "region" {
  type = string
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
  description = "VPC CIDR Block"
}

variable "public_0_cidr_block" {
  type = string
  default = "10.0.1.0/24"
}

variable "public_1_cidr_block" {
  type = string
  default = "10.0.2.0/24"
}

variable "private_0_cidr_block" {
  type = string
  default = "10.0.65.0/24"
}

variable "private_1_cidr_block" {
  type = string
  default = "10.0.66.0/24"
}

variable "cluster_capacity" {
  type = number
  default = 2
}