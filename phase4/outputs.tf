output "rds_endpoint" {
    description = "RDS instance endpoint"
    value       = aws_db_instance.ecoshop_rds.endpoint
}

output "rds_port" {
    description = "RDS instance port"
    value       = aws_db_instance.ecoshop_rds.port
}

output "rds_instance_id" {
    description = "RDS instance ID"
    value       = aws_db_instance.ecoshop_rds.identifier
}

output "db_subnet_group_name" {
    description = "Name of the DB subnet group"
    value       = aws_db_subnet_group.ecoshop_db_subnet_group.name
}

output "db_password" {
    description = "Database password"
    value       = var.db_password
    sensitive   = true
}
