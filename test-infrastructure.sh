#!/bin/bash
# test-infrastructure.sh
# Script pour tester l'infrastructure AWS

set -e

echo "🚀 Tests de l'Infrastructure AWS Terraform"
echo "=========================================="

# Vérifier que Terraform est appliqué
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Erreur: terraform.tfstate non trouvé. Appliquez d'abord 'terraform apply'"
    exit 1
fi

echo "📊 Récupération des informations de l'infrastructure..."

# Récupérer les outputs
BASTION_IP=$(terraform output -raw bastion_public_ip)
APP_IPS=($(terraform output -json app_instance_private_ips | jq -r '.[]'))
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
VPC_ID=$(terraform output -raw vpc_id)

echo "✅ Informations récupérées:"
echo "   - Bastion IP: $BASTION_IP"
echo "   - App Server 1 IP: ${APP_IPS[0]}"
echo "   - App Server 2 IP: ${APP_IPS[1]}"
echo "   - RDS Endpoint: $RDS_ENDPOINT"
echo "   - VPC ID: $VPC_ID"
echo ""

# Vérifier la clé SSH
KEY_FILE="phase2/bastion-key.pem"
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Erreur: Clé SSH non trouvée à $KEY_FILE"
    exit 1
fi

# Ajuster les permissions de la clé
chmod 600 "$KEY_FILE"

echo "🔍 Début des tests..."
echo ""

# Test 1: Connectivité SSH au Bastion
echo "1️⃣  Test: Connexion SSH au Bastion Host"
if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@$BASTION_IP "echo 'Connexion Bastion OK'" 2>/dev/null; then
    echo "   ✅ Connexion au Bastion: SUCCESS"
else
    echo "   ❌ Connexion au Bastion: FAILED"
    echo "   💡 Vérifiez que votre IP est autorisée dans le Security Group"
    exit 1
fi

# Test 2: Ping depuis Bastion vers serveurs App
echo ""
echo "2️⃣  Test: Ping depuis Bastion vers serveurs App"
for i in "${!APP_IPS[@]}"; do
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@$BASTION_IP "ping -c 3 ${APP_IPS[$i]}" >/dev/null 2>&1; then
        echo "   ✅ Ping vers App Server $((i+1)) (${APP_IPS[$i]}): SUCCESS"
    else
        echo "   ❌ Ping vers App Server $((i+1)) (${APP_IPS[$i]}): FAILED"
    fi
done

# Test 3: Accès internet depuis serveurs App
echo ""
echo "3️⃣  Test: Accès internet depuis serveurs App (via NAT Gateway)"
if ssh -i "$KEY_FILE" -J ec2-user@$BASTION_IP -o StrictHostKeyChecking=no ec2-user@${APP_IPS[0]} "curl -s --connect-timeout 10 https://www.google.com > /dev/null && echo 'Internet OK'" 2>/dev/null | grep -q "Internet OK"; then
    echo "   ✅ Accès internet depuis App Server 1: SUCCESS"
else
    echo "   ❌ Accès internet depuis App Server 1: FAILED"
fi

# Test 4: Vérification des services Apache
echo ""
echo "4️⃣  Test: Services Apache sur les serveurs App"
for i in "${!APP_IPS[@]}"; do
    SERVICE_STATUS=$(ssh -i "$KEY_FILE" -J ec2-user@$BASTION_IP -o StrictHostKeyChecking=no ec2-user@${APP_IPS[$i]} "systemctl is-active httpd" 2>/dev/null || echo "failed")
    if [ "$SERVICE_STATUS" = "active" ]; then
        echo "   ✅ Apache sur App Server $((i+1)): RUNNING"
        # Tester la page web
        PAGE_CONTENT=$(ssh -i "$KEY_FILE" -J ec2-user@$BASTION_IP -o StrictHostKeyChecking=no ec2-user@${APP_IPS[$i]} "curl -s localhost" 2>/dev/null || echo "failed")
        if [[ "$PAGE_CONTENT" =~ "Server:" ]]; then
            echo "   ✅ Page web App Server $((i+1)): ACCESSIBLE"
        else
            echo "   ⚠️  Page web App Server $((i+1)): NOT ACCESSIBLE"
        fi
    else
        echo "   ❌ Apache sur App Server $((i+1)): NOT RUNNING"
    fi
done

# Test 5: Connexion à la base de données
echo ""
echo "5️⃣  Test: Connexion à la base de données RDS"
DB_TEST=$(ssh -i "$KEY_FILE" -J ec2-user@$BASTION_IP -o StrictHostKeyChecking=no ec2-user@${APP_IPS[0]} "mysql -h $RDS_ENDPOINT -u admin -pEcoShop2024! -e 'SELECT 1;' 2>/dev/null && echo 'DB_OK'" 2>/dev/null || echo "DB_FAILED")
if [[ "$DB_TEST" =~ "DB_OK" ]]; then
    echo "   ✅ Connexion base de données: SUCCESS"
else
    echo "   ❌ Connexion base de données: FAILED"
    echo "   💡 Vérifiez que MySQL client est installé et que RDS est accessible"
fi

# Test 6: Sécurité - Test échec connexion directe
echo ""
echo "6️⃣  Test: Sécurité - Échec connexion directe aux serveurs App"
if timeout 10 ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@${APP_IPS[0]} "echo 'Direct connection'" 2>/dev/null; then
    echo "   ❌ Connexion directe possible: SECURITY ISSUE!"
else
    echo "   ✅ Connexion directe bloquée: SECURITY OK"
fi

echo ""
echo "🎉 Tests terminés!"
echo ""
echo "📝 Commandes utiles:"
echo "   Connexion Bastion:"
echo "   ssh -i phase2/bastion-key.pem ec2-user@$BASTION_IP"
echo ""
echo "   Connexion App Server 1:"
echo "   ssh -i phase2/bastion-key.pem -J ec2-user@$BASTION_IP ec2-user@${APP_IPS[0]}"
echo ""
echo "   Connexion App Server 2:"
echo "   ssh -i phase2/bastion-key.pem -J ec2-user@$BASTION_IP ec2-user@${APP_IPS[1]}"
echo ""
echo "   Connexion base de données:"
echo "   mysql -h $RDS_ENDPOINT -u admin -p ecoshop"
echo "   (mot de passe: EcoShop2024!)"
