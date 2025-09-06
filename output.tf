# outputs.tf

# Output du VPC
output "vpc_id" {
  value       = aws_vpc.ecosop_vpc.id
  description = "ID du VPC principal"
}

# Outputs des Subnets
output "web_public_subnet_a_id" {
  value       = aws_subnet.web_public_zone_a.id
  description = "ID du subnet public Web zone A"
}

output "web_public_subnet_b_id" {
  value       = aws_subnet.web_public_zone_b.id
  description = "ID du subnet public Web zone B"
}

output "app_private_subnet_a_id" {
  value       = aws_subnet.app_private_zone_a.id
  description = "ID du subnet privé App zone A"
}

output "app_private_subnet_b_id" {
  value       = aws_subnet.app_private_zone_b.id
  description = "ID du subnet privé App zone B"
}

output "db_private_subnet_a_id" {
  value       = aws_subnet.db_private_zone_a.id
  description = "ID du subnet privé DB zone A"
}

output "db_private_subnet_b_id" {
  value       = aws_subnet.db_private_zone_b.id
  description = "ID du subnet privé DB zone B"
}

# Outputs des Security Groups
output "sg_web_id" {
  value       = aws_security_group.ecosop_sg_web.id
  description = "ID du Security Group Web"
}

output "sg_app_id" {
  value       = aws_security_group.ecosop_sg_app.id
  description = "ID du Security Group App"
}

output "sg_db_id" {
  value       = aws_security_group.ecosop_sg_db.id
  description = "ID du Security Group DB"
}

output "sg_bastion_id" {
  value       = aws_security_group.ecosop_sg_bastion.id
  description = "ID du Security Group Bastion"
}

# Outputs des Instances (Phase 3)
output "bastion_host_public_ip" {
  value       = aws_instance.bastion_host.public_ip
  description = "IP publique du Bastion Host"
}

output "app_server_a_private_ip" {
  value       = aws_instance.app_server_a.private_ip
  description = "IP privée du serveur App A"
}

output "app_server_b_private_ip" {
  value       = aws_instance.app_server_b.private_ip
  description = "IP privée du serveur App B"
}

# Outputs pour RDS (Phase 4)
output "rds_endpoint" {
  value       = aws_db_instance.ecoshop_rds.endpoint
  description = "Endpoint de l'instance RDS"
}

output "rds_address" {
  value       = aws_db_instance.ecoshop_rds.address
  description = "Adresse de l'instance RDS pour connexion"
}

# Outputs pour Load Balancer (Phase 5)
output "alb_dns_name" {
  value       = aws_lb.ecoshop_alb.dns_name
  description = "DNS name de l'Application Load Balancer"
}

output "alb_zone_id" {
  value       = aws_lb.ecoshop_alb.zone_id
  description = "Zone ID de l'ALB pour Route53 si needed"
}

# Outputs pour la paire de clés SSH générée
output "private_key" {
  value       = tls_private_key.ec2_key.private_key_pem
  description = "Clé privée SSH (gardez-la secrète !)"
  sensitive   = true
}

output "public_key" {
  value       = tls_private_key.ec2_key.public_key_openssh
  description = "Clé publique SSH"
}