# main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Provider AWS
provider "aws" {
  region = var.region
}

# Data source pour AMI Amazon Linux 2 latest (pour Phase 3)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Génération d'une paire de clés SSH
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Import de la clé publique dans AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "ecosop-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Création du VPC
resource "aws_vpc" "ecosop_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ecosop-vpc"
  }
}

# Sous-réseaux publics (Web tier)
resource "aws_subnet" "web_public_zone_a" {
  vpc_id                  = aws_vpc.ecosop_vpc.id
  cidr_block              = var.web_public_subnet_cidr_1
  map_public_ip_on_launch = true
  availability_zone       = var.zone_a
  tags = {
    Name = "ecosop-web-public-zone-a"
  }
}

resource "aws_subnet" "web_public_zone_b" {
  vpc_id                  = aws_vpc.ecosop_vpc.id
  cidr_block              = var.web_public_subnet_cidr_2
  map_public_ip_on_launch = true
  availability_zone       = var.zone_b
  tags = {
    Name = "ecosop-web-public-zone-b"
  }
}

# Sous-réseaux privés (App tier)
resource "aws_subnet" "app_private_zone_a" {
  vpc_id                  = aws_vpc.ecosop_vpc.id
  cidr_block              = var.app_private_subnet_cidr_1
  map_public_ip_on_launch = false
  availability_zone       = var.zone_a
  tags = {
    Name = "ecosop-app-private-zone-a"
  }
}

resource "aws_subnet" "app_private_zone_b" {
  vpc_id                  = aws_vpc.ecosop_vpc.id
  cidr_block              = var.app_private_subnet_cidr_2
  map_public_ip_on_launch = false
  availability_zone       = var.zone_b
  tags = {
    Name = "ecosop-app-private-zone-b"
  }
}

# Sous-réseaux privés (DB tier)
resource "aws_subnet" "db_private_zone_a" {
  vpc_id                  = aws_vpc.ecosop_vpc.id
  cidr_block              = var.db_private_subnet_cidr_1
  map_public_ip_on_launch = false
  availability_zone       = var.zone_a
  tags = {
    Name = "ecosop-db-private-zone-a"
  }
}

resource "aws_subnet" "db_private_zone_b" {
  vpc_id                  = aws_vpc.ecosop_vpc.id
  cidr_block              = var.db_private_subnet_cidr_2
  map_public_ip_on_launch = false
  availability_zone       = var.zone_b
  tags = {
    Name = "ecosop-db-private-zone-b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.ecosop_vpc.id
  tags = {
    Name = "ecosop-internet-gateway"
  }
}

# Elastic IP pour NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "ecosop-nat-eip"
  }
}

# NAT Gateway dans un subnet public
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.web_public_zone_a.id
  tags = {
    Name = "ecosop-nat-gateway"
  }
  depends_on = [aws_internet_gateway.gw]
}

# Table de routage publique
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecosop_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "ecosop-public-route-table"
  }
}

# Table de routage privée
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ecosop_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "ecosop-private-route-table"
  }
}

# Associations des tables de routage
resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.web_public_zone_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.web_public_zone_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "app_private_assoc_a" {
  subnet_id      = aws_subnet.app_private_zone_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "app_private_assoc_b" {
  subnet_id      = aws_subnet.app_private_zone_b.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "db_private_assoc_a" {
  subnet_id      = aws_subnet.db_private_zone_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "db_private_assoc_b" {
  subnet_id      = aws_subnet.db_private_zone_b.id
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups

# SG-Web (pour Load Balancer)
resource "aws_security_group" "ecosop_sg_web" {
  name        = "ecosop-SG-Web"
  description = "Security group for Web Load Balancer"
  vpc_id      = aws_vpc.ecosop_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecosop-SG-Web"
  }
}

# SG-App (pour serveurs applicatifs)
resource "aws_security_group" "ecosop_sg_app" {
  name        = "ecosop-SG-App"
  description = "Security group for Application servers"
  vpc_id      = aws_vpc.ecosop_vpc.id

  ingress {
    from_port       = 80  # Changé de 8080 à 80 pour matcher target group
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecosop_sg_web.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ecosop_sg_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecosop-SG-App"
  }
}

# SG-DB (pour base de données)
resource "aws_security_group" "ecosop_sg_db" {
  name        = "ecosop-SG-DB"
  description = "Security group for Database"
  vpc_id      = aws_vpc.ecosop_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecosop_sg_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecosop-SG-DB"
  }
}

# SG-Bastion (pour administration)
resource "aws_security_group" "ecosop_sg_bastion" {
  name        = "ecosop-SG-Bastion"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.ecosop_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecosop-SG-Bastion"
  }
}

# Phase 3: Déploiement des Serveurs

# Bastion Host
resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web_public_zone_a.id     # Dans un subnet public
  key_name               = aws_key_pair.generated_key.key_name # Utilise la clé générée
  vpc_security_group_ids = [aws_security_group.ecosop_sg_bastion.id]

  tags = {
    Name = "ecosop-bastion-host"
  }
}

# Serveurs App (2 instances, dans différentes AZ privées)
resource "aws_instance" "app_server_a" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app_private_zone_a.id
  key_name               = aws_key_pair.generated_key.key_name # Utilise la clé générée
  vpc_security_group_ids = [aws_security_group.ecosop_sg_app.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd php mysql
    systemctl start httpd
    systemctl enable httpd
    echo "<?php echo 'Server: ' . gethostname(); ?>" > /var/www/html/index.php
    # Test de connectivité DB (remplacez RDS_ENDPOINT par l'endpoint réel après déploiement)
    mysql -h RDS_ENDPOINT -u ${var.db_username} -p${var.db_password} -e "CREATE DATABASE IF NOT EXISTS ${var.db_name}; USE ${var.db_name}; CREATE TABLE IF NOT EXISTS test_table (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255)); INSERT INTO test_table (name) VALUES ('Test from App A');"
  EOF

  tags = {
    Name = "ecosop-app-server-a"
  }

  depends_on = [aws_db_instance.ecoshop_rds]
}

resource "aws_instance" "app_server_b" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app_private_zone_b.id
  key_name               = aws_key_pair.generated_key.key_name # Utilise la clé générée
  vpc_security_group_ids = [aws_security_group.ecosop_sg_app.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd php mysql
    systemctl start httpd
    systemctl enable httpd
    echo "<?php echo 'Server: ' . gethostname(); ?>" > /var/www/html/index.php
    # Test de connectivité DB (remplacez RDS_ENDPOINT par l'endpoint réel après déploiement)
    mysql -h RDS_ENDPOINT -u ${var.db_username} -p${var.db_password} -e "CREATE DATABASE IF NOT EXISTS ${var.db_name}; USE ${var.db_name}; CREATE TABLE IF NOT EXISTS test_table (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255)); INSERT INTO test_table (name) VALUES ('Test from App B');"
  EOF

  tags = {
    Name = "ecosop-app-server-b"
  }

  depends_on = [aws_db_instance.ecoshop_rds]
}

# Phase 4: Base de Données RDS

# DB Subnet Group
resource "aws_db_subnet_group" "ecoshop_db_subnet_group" {
  name       = "ecoshop-db-subnet-group"
  subnet_ids = [aws_subnet.db_private_zone_a.id, aws_subnet.db_private_zone_b.id]

  tags = {
    Name = "ecoshop-db-subnet-group"
  }
}

# Instance RDS MySQL (modifiée pour plus légère/rapide : single AZ)
resource "aws_db_instance" "ecoshop_rds" {
  identifier             = "ecoshop-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  multi_az               = false # Changé pour false : plus rapide à créer, moins HA
  db_subnet_group_name   = aws_db_subnet_group.ecoshop_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.ecosop_sg_db.id]
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true # Pour test, évite snapshot à la destruction

  tags = {
    Name = "ecoshop-rds"
  }
}

# Phase 5: Load Balancer

# Application Load Balancer
resource "aws_lb" "ecoshop_alb" {
  name               = "ecoshop-alb"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecosop_sg_web.id]
  subnets            = [aws_subnet.web_public_zone_a.id, aws_subnet.web_public_zone_b.id]

  tags = {
    Name = "ecoshop-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "ecoshop_tg" {
  name     = "ecoshop-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecosop_vpc.id

  health_check {
    path     = "/index.php"
    protocol = "HTTP"
    matcher  = "200"
    interval = 30
  }

  tags = {
    Name = "ecoshop-tg"
  }
}

# Attachments des targets (app servers)
resource "aws_lb_target_group_attachment" "app_server_a_attachment" {
  target_group_arn = aws_lb_target_group.ecoshop_tg.arn
  target_id        = aws_instance.app_server_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_server_b_attachment" {
  target_group_arn = aws_lb_target_group.ecoshop_tg.arn
  target_id        = aws_instance.app_server_b.id
  port             = 80
}

# Listener
resource "aws_lb_listener" "ecoshop_listener" {
  load_balancer_arn = aws_lb.ecoshop_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecoshop_tg.arn
  }
}