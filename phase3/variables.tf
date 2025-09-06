variable "region" {
    description = "Région AWS"
    type        = string
    default     = "us-east-1"  # Paris
}
variable "bastion_ssh_key" {
	description = "Nom de la clé SSH pour le Bastion Host"
	type        = string
    default     = "bastion-key"
}

variable "vpc_id" {
	description = "ID du VPC"
	type        = string
}

variable "my_ip" {
	description = "Adresse IP autorisée pour SSH sur le Bastion"
	type        = string
    default     = "0.0.0.0/0"
}

variable "ami_bastion" {
	description = "AMI pour le Bastion Host"
	type        = string
    default = "ami-0e95a5e2743ec9ec9"
}

variable "public_subnet_id" {
	description = "ID du subnet public pour le Bastion Host"
	type        = string
    default     = "subnet-0abcd1234efgh5678"
}

variable "ami_webapp" {
	description = "AMI pour les serveurs Web/App (Amazon Linux 2)"
	type        = string
    default = "ami-0360c520857e3138f"
}

variable "app_private_subnet_ids" {
	description = "Liste des IDs des subnets privés pour les serveurs Web/App"
	type        = list(string)
}

variable "sg_bastion_id" {
	description = "ID du Security Group Bastion (depuis phase2)"
	type        = string
}

variable "sg_app_id" {
	description = "ID du Security Group App (depuis phase2)"
	type        = string
}

variable "rds_endpoint" {
	description = "Endpoint RDS depuis phase4"
	type        = string
	default     = ""
}

variable "db_password" {
	description = "Mot de passe base de données RDS"
	type        = string
	default     = "EcoShop2024!"
	sensitive   = true
}
