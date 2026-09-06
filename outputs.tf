output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Public DNS address of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "Direct HTTP access URL for the load balanced web stack."
  value       = "http://${module.alb.alb_dns_name}"
}

output "health_check_url" {
  description = "Health probe URL inspected by the ALB and CI/CD automated rollbacks."
  value       = "http://${module.alb.alb_dns_name}/health"
}

output "rds_endpoint" {
  description = "Private connection endpoint for the PostgreSQL RDS instance."
  value       = module.rds.rds_endpoint
}
