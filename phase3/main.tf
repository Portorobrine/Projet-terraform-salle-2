# Bastion Host
# resource "aws_security_group" "sg_bastion" {
# 	name        = "SG-Bastion"
# 	description = "SSH access for Bastion Host" # Remplacer par du texte ASCII
# 	vpc_id      = var.vpc_id

# 	ingress {
# 		from_port   = 22
# 		to_port     = 22
# 		protocol    = "tcp"
# 		cidr_blocks = [var.my_ip]
# 	}

# 	egress {
# 		from_port   = 0
# 		to_port     = 0
# 		protocol    = "-1"
# 		cidr_blocks = ["0.0.0.0/0"]
# 	}
# }

resource "aws_instance" "bastion" {
	ami           = var.ami_bastion
	instance_type = "t3.micro"
	subnet_id     = var.public_subnet_id
	key_name      = var.bastion_ssh_key
	vpc_security_group_ids = [var.sg_bastion_id]
	user_data = base64encode(<<-EOF
		#!/bin/bash
		set -e
		
		# Log de configuration
		exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
		echo "Configuration du Bastion Host..."
		
		# Mise à jour et installation d'outils utiles
		yum update -y
		yum install -y mysql telnet nmap wget curl htop tree
		
		# Configuration SSH pour jumping
		echo "Host *" >> /home/ec2-user/.ssh/config
		echo "    StrictHostKeyChecking no" >> /home/ec2-user/.ssh/config
		echo "    UserKnownHostsFile=/dev/null" >> /home/ec2-user/.ssh/config
		chown ec2-user:ec2-user /home/ec2-user/.ssh/config
		chmod 600 /home/ec2-user/.ssh/config
		
		# Script de test rapide
		cat > /home/ec2-user/test-connectivity.sh << 'TESTEOF'
#!/bin/bash
echo "🔍 Test de connectivité depuis Bastion"
echo "====================================="
echo "✅ Bastion opérationnel: $(hostname -f)"
echo "📊 Route par défaut: $(ip route | grep default)"
echo "🌐 Test Internet: $(ping -c 1 8.8.8.8 >/dev/null && echo 'OK' || echo 'FAILED')"
TESTEOF
		chmod +x /home/ec2-user/test-connectivity.sh
		chown ec2-user:ec2-user /home/ec2-user/test-connectivity.sh
		
		echo "✅ Bastion configuré avec succès!"
	EOF
	)
	tags = {
		Name = "Bastion-Host"
	}
}

# Serveurs Web/App
resource "aws_instance" "webapp" {
	count         = 2
	ami           = var.ami_webapp
	instance_type = "t3.small"
	subnet_id     = element(var.app_private_subnet_ids, count.index)
	key_name      = var.bastion_ssh_key
	vpc_security_group_ids = [var.sg_app_id]
	user_data = base64encode(<<-EOF
		#!/bin/bash
		set -e
		
		# Log de démarrage
		exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
		echo "Début de la configuration du serveur Web/App..."
		
		# Mise à jour du système
		echo "Mise à jour du système..."
		yum update -y
		
		# Installation d'Apache, PHP et MySQL client
		echo "Installation des packages..."
		yum install -y httpd php php-mysqlnd mysql wget curl
		
		# Configuration d'Apache
		echo "Configuration d'Apache..."
		systemctl start httpd
		systemctl enable httpd
		
		# Création d'une page de test PHP
		cat > /var/www/html/index.php << 'PHPEOF'
<?php
echo "<h1>Serveur Web/App: " . gethostname() . "</h1>";
echo "<h2>Informations PHP</h2>";
echo "Version PHP: " . phpversion() . "<br>";
echo "Date: " . date('Y-m-d H:i:s') . "<br>";
echo "<h2>Test Base de Données</h2>";
try {
    $pdo = new PDO('mysql:host=${var.rds_endpoint};dbname=ecoshop', 'admin', '${var.db_password}');
    echo "✅ Connexion DB: OK<br>";
    $stmt = $pdo->query('SELECT VERSION() as version');
    $version = $stmt->fetch();
    echo "Version MySQL: " . $version['version'] . "<br>";
} catch(PDOException $e) {
    echo "❌ Erreur DB: " . $e->getMessage() . "<br>";
}
echo "<h2>Test Connectivité</h2>";
echo "Gateway par défaut: " . exec("ip route | grep default | awk '{print $3}'") . "<br>";
$ping_test = exec("ping -c 1 8.8.8.8 2>/dev/null && echo 'OK' || echo 'FAILED'");
echo "Test Internet (ping 8.8.8.8): " . $ping_test . "<br>";
phpinfo();
?>
PHPEOF
		
		# Test des services
		echo "Test des services..."
		systemctl status httpd
		php -v
		
		# Configuration du firewall local
		systemctl stop firewalld
		systemctl disable firewalld
		
		echo "Configuration terminée avec succès!"
		echo "Serveur prêt: $(date)"
	EOF
	)
	tags = {
		Name = "WebApp-${count.index + 1}"
	}
}
