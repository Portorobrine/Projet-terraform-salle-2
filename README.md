# 🏗️ EcoShop - Infrastructure AWS avec Terraform

## 📋 Vue d'ensemble

Ce projet déploie une infrastructure AWS complète pour l'application **EcoShop** en utilisant Terraform. L'architecture implémente une solution scalable, sécurisée et hautement disponible avec separation des tiers (Web, Application, Base de données).

## 🏛️ Architecture

L'infrastructure est organisée en **5 phases** principales :

### Phase 1 : Infrastructure Réseau (VPC)
- **VPC** : Réseau privé virtuel (10.0.0.0/16)
- **Subnets publics** : 2 subnets Web dans différentes AZ
- **Subnets privés App** : 2 subnets pour serveurs applicatifs
- **Subnets privés DB** : 2 subnets pour base de données
- **Internet Gateway** : Accès Internet pour subnets publics
- **NAT Gateway** : Accès Internet sortant pour subnets privés
- **Tables de routage** : Routage public et privé

### Phase 2 : Sécurité (Security Groups)
- **SG-Web** : Load Balancer (ports 80/443 depuis Internet)
- **SG-App** : Serveurs applicatifs (port 80 depuis LB, SSH depuis Bastion)
- **SG-DB** : Base de données (port 3306 depuis serveurs App)
- **SG-Bastion** : Bastion Host (SSH depuis votre IP)
- **Génération clés SSH** : Paire de clés RSA 2048 automatique

### Phase 3 : Serveurs de Calcul
- **Bastion Host** : t3.micro en subnet public pour administration
- **Serveurs App** : 2x t3.small en subnets privés avec Apache/PHP
- **User Data** : Installation automatique des services web

### Phase 4 : Base de Données
- **RDS MySQL 8.0** : Instance db.t3.micro Multi-AZ
- **Subnet Group** : Distribution sur les 2 AZ privées
- **Chiffrement** : Données au repos sécurisées

### Phase 5 : Load Balancer
- **Application Load Balancer** : Distribution du trafic
- **Target Group** : Health checks sur les serveurs App
- **Listener** : Redirection HTTP vers serveurs


## 🚀 Déploiement Rapide

### Prérequis
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configuré
- Compte AWS avec permissions appropriées

### 1. Cloner le Projet
```bash
git clone https://github.com/Portorobrine/Projet-terraform-salle-2.git
cd Projet-terraform-salle-2
```

### 2. Configuration AWS
```bash
# Configurer vos credentials AWS
aws configure

# Ou utiliser des variables d'environnement
export AWS_ACCESS_KEY_ID="votre-access-key"
export AWS_SECRET_ACCESS_KEY="votre-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. Personnaliser les Variables
Éditez `variables.tf` pour personnaliser :
```hcl
variable "region" {
  default = "us-east-1"  # Votre région préférée
}

variable "my_ip" {
  default = "1.2.3.4/32"  # Votre IP publique pour SSH Bastion
}
```

### 4. Déployer l'Infrastructure
```bash
# Initialiser Terraform
terraform init

# Prévisualiser les changements
terraform plan

# Déployer l'infrastructure
terraform apply
```

⏱️ **Temps de déploiement** : ~10-15 minutes

## 🔑 Accès et Connexion

### Récupération des Informations
```bash
# IP publique du Bastion
terraform output bastion_host_public_ip

# Endpoint de la base de données
terraform output rds_endpoint

# URL du Load Balancer
terraform output alb_dns_name

# Clé privée SSH (sensible)
terraform output -raw private_key > ecoshop-key.pem
chmod 600 ecoshop-key.pem
```

### Connexion SSH
```bash
# Connexion au Bastion Host
ssh -i ecosop-key.pem ec2-user@$(terraform output -raw bastion_host_public_ip)

# Connexion aux serveurs App via Bastion (Jump Host)
ssh -i ecosop-key.pem -J ec2-user@BASTION_IP ec2-user@APP_SERVER_IP
```

### Test de l'Application
```bash
# Accéder à l'application via le Load Balancer
curl http://$(terraform output -raw alb_dns_name)

# Ou ouvrir dans le navigateur
open http://$(terraform output -raw alb_dns_name)
```

## 📊 Tests et Validation

### Tests de Connectivité
```bash
# Test des Security Groups
# Ping depuis Bastion vers App Servers (doit fonctionner)
ping APP_SERVER_IP

# Test SSH depuis Bastion vers App Servers
ssh ec2-user@APP_SERVER_IP

# Test connexion base de données depuis App Server
mysql -h RDS_ENDPOINT -u admin -p
```

### Health Checks
- **Load Balancer** : Health checks automatiques sur `/index.php`
- **RDS** : Multi-AZ avec basculement automatique
- **Auto-scaling** : Prêt pour extension future

## 🛡️ Sécurité

### Principes Appliqués
- **Least Privilege** : Security Groups restrictifs
- **Defense in Depth** : Séparation des tiers réseau
- **Bastion Host** : Point d'accès SSH unique et sécurisé
- **Chiffrement** : RDS avec chiffrement au repos
- **Isolation** : Subnets privés pour App/DB sans accès Internet entrant

### Security Groups
| Groupe | Ingress | Egress | Usage |
|--------|---------|---------|--------|
| SG-Web | 80, 443 (0.0.0.0/0) | All | Load Balancer |
| SG-App | 80 (SG-Web), 22 (SG-Bastion) | All | App Servers |
| SG-DB | 3306 (SG-App) | All | Database |
| SG-Bastion | 22 (Your IP) | All | Admin Access |

## 🎛️ Configuration

### Variables Principales
| Variable | Description | Défaut | Exemple |
|----------|-------------|---------|---------|
| `region` | Région AWS | `us-east-1` | `eu-west-1` |
| `my_ip` | IP pour accès SSH Bastion | `0.0.0.0/0` | `203.0.113.1/32` |
| `db_password` | Mot de passe RDS | `EcoShop2024!` | `VotreMotDePasse123!` |
| `db_name` | Nom de la base | `ecoshop` | `production_db` |

### Personnalisation Avancée
```hcl
# variables.tf - Exemples de personnalisation

# Tailles d'instances
variable "bastion_instance_type" {
  default = "t3.micro"    # ou t3.small pour plus de performance
}

variable "app_instance_type" {
  default = "t3.small"    # ou t3.medium pour plus de charge
}

# Base de données
variable "db_instance_class" {
  default = "db.t3.micro" # ou db.t3.small pour plus de performance
}
```

## 📈 Monitoring et Logs

### CloudWatch Integration
- **Métriques EC2** : CPU, Mémoire, Réseau automatiques
- **Métriques RDS** : Connexions, IOPS, CPU base
- **Métriques ALB** : Requêtes, latence, codes d'erreur

### Logs Importants
```bash
# Logs des User Data Scripts (installation services)
sudo tail -f /var/log/cloud-init-output.log

# Logs Apache
sudo tail -f /var/log/httpd/access_log
sudo tail -f /var/log/httpd/error_log

# Logs système
sudo journalctl -u httpd -f
```

## 🔄 Gestion du Cycle de Vie

### Mise à Jour
```bash
# Mise à jour de l'infrastructure
terraform plan
terraform apply

# Mise à jour sélective (exemple: seulement les instances)
terraform apply -target=aws_instance.app_server_a
```

### Sauvegarde
```bash
# Backup du state Terraform
cp terraform.tfstate terraform.tfstate.backup-$(date +%Y%m%d)

# Export de la configuration
terraform show > infrastructure-current.txt
```

### Destruction
```bash
# Détruire toute l'infrastructure (⚠️ IRRÉVERSIBLE)
terraform destroy

# Destruction sélective
terraform destroy -target=aws_instance.app_server_a
```

## 🚨 Dépannage

### Problèmes Courants

#### 1. Erreur de Connexion SSH
```bash
# Vérifier les Security Groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Vérifier l'IP publique du Bastion
terraform refresh
terraform output bastion_host_public_ip
```

#### 2. Application Inaccessible
```bash
# Vérifier le Load Balancer
aws elbv2 describe-load-balancers
aws elbv2 describe-target-health --target-group-arn arn:aws:...

# Vérifier les services sur les instances
ssh -i ecosop-key.pem ec2-user@BASTION_IP
sudo systemctl status httpd
```

#### 3. Base de Données Inaccessible
```bash
# Test de connectivité depuis App Server
telnet RDS_ENDPOINT 3306

# Vérifier les Security Groups RDS
aws rds describe-db-instances --db-instance-identifier ecoshop-db
```

### Logs de Debug
```bash
# Terraform debug
export TF_LOG=DEBUG
terraform apply

# AWS CLI debug
aws ec2 describe-instances --debug
```

---
## Auteur
Lucas, Mathéo, Jeremie, Julien, Sébastien - Projet Terraform AWS Infrastructure

---




