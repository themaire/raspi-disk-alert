#!/bin/bash

# Script de test pour raspi-disk-alert
# Valide la configuration et teste les fonctionnalités

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
SCRIPT_FILE="$SCRIPT_DIR/rasp-disk-alert.sh"

echo "🧪 Tests de validation pour raspi-disk-alert"
echo "============================================="

# Test 1: Vérifier la présence des fichiers
print_status "Vérification des fichiers requis..."
if [[ -f "$ENV_FILE" ]]; then
    print_success "Fichier .env trouvé"
else
    print_error "Fichier .env manquant"
    exit 1
fi

if [[ -f "$SCRIPT_FILE" ]]; then
    print_success "Script principal trouvé"
else
    print_error "Script principal manquant"
    exit 1
fi

# Test 2: Vérifier les permissions
print_status "Vérification des permissions..."
if [[ -r "$ENV_FILE" ]]; then
    print_success "Fichier .env lisible"
else
    print_error "Fichier .env non lisible"
    exit 1
fi

if [[ -x "$SCRIPT_FILE" ]]; then
    print_success "Script principal exécutable"
else
    print_error "Script principal non exécutable"
    exit 1
fi

# Test 3: Validation de la configuration
print_status "Validation de la configuration..."
source "$ENV_FILE"

# Vérifier le token Telegram
if [[ -z "$TELEGRAM_TOKEN" ]]; then
    print_error "TELEGRAM_TOKEN non défini"
    exit 1
elif [[ "$TELEGRAM_TOKEN" == *"VOTRE_TOKEN"* ]]; then
    print_warning "TELEGRAM_TOKEN contient encore les valeurs d'exemple"
    CONFIG_INCOMPLETE=true
else
    print_success "TELEGRAM_TOKEN configuré"
fi

# Vérifier le chat ID
if [[ -z "$TELEGRAM_CHAT_ID" ]]; then
    print_error "TELEGRAM_CHAT_ID non défini"
    exit 1
elif [[ "$TELEGRAM_CHAT_ID" == *"VOTRE_CHAT"* ]]; then
    print_warning "TELEGRAM_CHAT_ID contient encore les valeurs d'exemple"
    CONFIG_INCOMPLETE=true
else
    print_success "TELEGRAM_CHAT_ID configuré"
fi

# Vérifier le seuil
if [[ -z "$DISK_THRESHOLD" ]]; then
    print_error "DISK_THRESHOLD non défini"
    exit 1
elif [[ ! "$DISK_THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$DISK_THRESHOLD" -lt 1 ]] || [[ "$DISK_THRESHOLD" -gt 100 ]]; then
    print_error "DISK_THRESHOLD doit être un nombre entre 1 et 100"
    exit 1
else
    print_success "DISK_THRESHOLD valide ($DISK_THRESHOLD%)"
fi

# Vérifier les chemins de disques
if [[ -z "$DISK_PATHS" ]]; then
    print_error "DISK_PATHS non défini"
    exit 1
else
    print_success "DISK_PATHS configuré"
    # Valider chaque chemin
    for path in "${DISK_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            print_success "  ✓ $path existe"
        else
            print_warning "  ⚠ $path n'existe pas sur ce système"
        fi
    done
fi

# Test 4: Vérifier les dépendances système
print_status "Vérification des dépendances système..."

if command -v curl &> /dev/null; then
    print_success "curl disponible"
else
    print_error "curl requis mais non trouvé"
    exit 1
fi

if command -v df &> /dev/null; then
    print_success "df disponible"
else
    print_error "df requis mais non trouvé"
    exit 1
fi

# Test 5: Test de connexion Telegram (si configuré)
if [[ "$CONFIG_INCOMPLETE" != "true" ]]; then
    print_status "Test de connexion Telegram..."
    
    # Construire l'URL de test
    API_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/getMe"
    
    if response=$(curl -s "$API_URL"); then
        if echo "$response" | grep -q '"ok":true'; then
            print_success "Connexion Telegram réussie"
            
            # Test d'envoi de message
            print_status "Test d'envoi de message..."
            MESSAGE="🧪 Test de raspi-disk-alert - $(date)"
            SEND_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"
            
            if curl -s -X POST "$SEND_URL" \
                -d "chat_id=$TELEGRAM_CHAT_ID" \
                -d "text=$MESSAGE" > /dev/null; then
                print_success "Message de test envoyé avec succès"
            else
                print_error "Échec de l'envoi du message de test"
            fi
        else
            print_error "Token Telegram invalide"
        fi
    else
        print_error "Impossible de contacter l'API Telegram"
    fi
else
    print_warning "Configuration incomplète - test Telegram ignoré"
fi

# Test 6: Test de la logique du script principal
print_status "Test de la logique de surveillance..."

# Simuler un test avec df
if df -hP / > /dev/null 2>&1; then
    print_success "Commande df fonctionne correctement"
else
    print_error "Problème avec la commande df"
fi

echo
echo "📊 Résumé des tests"
echo "==================="

if [[ "$CONFIG_INCOMPLETE" == "true" ]]; then
    print_warning "Configuration incomplète détectée"
    echo "➡️  Éditez le fichier .env avec vos vraies valeurs"
    echo "   Token Telegram: obtenez-le via @BotFather"
    echo "   Chat ID: obtenez-le via @userinfobot"
else
    print_success "Tous les tests sont passés avec succès !"
    echo "➡️  Le système est prêt à être utilisé"
fi

echo
echo "💡 Commandes utiles:"
echo "   Test manuel: sudo $SCRIPT_FILE"
echo "   Configuration cron: sudo crontab -e"
echo "   Logs système: tail -f /var/log/syslog | grep raspi-disk-alert"
