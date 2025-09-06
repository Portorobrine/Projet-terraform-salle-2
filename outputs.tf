# =======================
# OUTPUTS PRINCIPAUX POUR LES TESTS
# =======================

# ===== RÉSEAU (Phase 1) =====
output "vpc_id" {
    description = "ID du VPC principal"
    value       = module.phase1.vpc_id
}

output "public_subnet_ids" {
    description = "IDs des subnets publics"
    value       = module.phase1.web_public_subnet_ids
}

output "app_private_subnet_ids" {
    description = "IDs des subnets privés App"
    value       = module.phase1.app_private_subnet_ids
}

output "db_private_subnet_ids" {
    description = "IDs des subnets privés DB"
    value       = module.phase1.db_private_subnet_ids
}

# ===== SÉCURITÉ (Phase 2) =====
output "bastion_key_name" {
    description = "Nom de la clé SSH pour le Bastion"
    value       = module.phase2.bastion_key_name
}

# ===== INSTANCES (Phase 3) =====
output "bastion_public_ip" {
    description = "IP publique du Bastion Host"
    value       = module.phase3.bastion_public_ip
}

output "bastion_private_ip" {
    description = "IP privée du Bastion Host"
    value       = module.phase3.bastion_private_ip
}

output "app_instance_private_ips" {
    description = "IPs privées des serveurs Web/App"
    value       = module.phase3.app_instance_private_ips
}

output "app_instance_ids" {
    description = "IDs des instances Web/App"
    value       = module.phase3.app_instance_ids
}

# ===== BASE DE DONNÉES (Phase 4) =====
output "rds_endpoint" {
    description = "Endpoint de la base de données RDS"
    value       = module.phase4.rds_endpoint
}

output "rds_port" {
    description = "Port de la base de données RDS"
    value       = module.phase4.rds_port
}

# ===== INFORMATIONS DE CONNEXION =====
output "ssh_connection_commands" {
    description = "Commandes SSH pour se connecter aux instances"
    value = {
        bastion = "ssh -i phase2/bastion-key.pem ec2-user@${module.phase3.bastion_public_ip}"
        webapp1 = "ssh -i phase2/bastion-key.pem -J ec2-user@${module.phase3.bastion_public_ip} ec2-user@${module.phase3.app_instance_private_ips[0]}"
        webapp2 = "ssh -i phase2/bastion-key.pem -J ec2-user@${module.phase3.bastion_public_ip} ec2-user@${module.phase3.app_instance_private_ips[1]}"
    }
}

output "database_connection" {
    description = "Informations de connexion à la base de données"
    value = {
        host     = module.phase4.rds_endpoint
        port     = module.phase4.rds_port
        database = "ecoshop"
        username = "admin"
        command  = "mysql -h ${module.phase4.rds_endpoint} -u admin -p ecoshop"
    }
    sensitive = true
}