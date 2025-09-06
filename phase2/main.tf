# Data source pour récupérer le VPC par tag (créé dans le root ou phase1)
# SG-Web (pour Load Balancer)
resource "aws_security_group" "sg_web" {
  name        = "SG-Web"
  description = "Security group for Web Load Balancer"
  vpc_id      = var.vpc_id

  # Ingress HTTP depuis Internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress HTTPS depuis Internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress tout sortant (par défaut, mais explicite pour least privilege)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Web"
  }
}

# SG-App (pour serveurs applicatifs)
resource "aws_security_group" "sg_app" {
  name        = "SG-App"
  description = "Security group for Application servers"
  vpc_id      = var.vpc_id

  # Ingress port 80 depuis SG-Web uniquement
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
  }

  # Ingress SSH (22) depuis SG-Bastion uniquement
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  # Ingress ICMP (ping) depuis SG-Bastion
  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  # Egress tout sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-App"
  }
}

# SG-DB (pour base de données)
resource "aws_security_group" "sg_db" {
  name        = "SG-DB"
  description = "Security group for Database"
  vpc_id      = var.vpc_id

  # Ingress MySQL (3306) depuis SG-App uniquement
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  # Egress tout sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-DB"
  }
}

# SG-Bastion (pour administration)
resource "aws_security_group" "sg_bastion" {
  name        = "SG-Bastion"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  # Ingress SSH (22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Egress tout sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Bastion"
  }
}

# Génération de la clé privée
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Création de la paire de clés dans AWS
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# Sauvegarde locale de la clé privée (optionnel)
resource "local_file" "bastion_private_key" {
  content         = tls_private_key.bastion_key.private_key_pem
  filename        = "${path.module}/bastion-key.pem"
  file_permission = "0600"
}