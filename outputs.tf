output "alb_dns_name" {
  value       = aws_lb.presto_alb.dns_name
  description = "The DNS name of the ALB connecting to coordinator instance"
}