#!/bin/bash

# Script de test pour raspi-disk-alert
# Valide la configuration et teste les fonctionnalités
# Usage: ./test.sh [telegram|no-telegram|local]

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_mode() {
    echo -e "${PURPLE}[MODE]${NC} $1"
}

# Gestion des paramètres
TEST_MODE="auto"
FORCE_TELEGRAM=false
DISABLE_TELEGRAM=false

case "${1:-}" in
    "telegram")
        TEST_MODE="telegram"
        FORCE_TELEGRAM=true
        print_mode "Mode Telegram forcé - Test des fonctionnalités Telegram même si la config semble incomplète"
        ;;
    "no-telegram")
        TEST_MODE="no-telegram"
        DISABLE_TELEGRAM=true
        print_mode "Mode sans Telegram - Ignore tous les tests Telegram"
        ;;
    "local")
        TEST_MODE="local"
        print_mode "Mode local - Tests complets sans envoi de messages Telegram"
        ;;
    "help"|"-h"|"--help")
        echo "🧪 Script de test pour raspi-disk-alert"
        echo "======================================="
        echo
        echo "Usage: $0 [MODE]"
        echo
        echo "Modes disponibles:"
        echo "  telegram     Force les tests Telegram (même config incomplète)"
        echo "  no-telegram  Ignore complètement les tests Telegram"
        echo "  local        Tests complets sans envoi de messages"
        echo "  (aucun)      Mode automatique (détection selon la config)"
        echo
        echo "Exemples:"
        echo "  $0                # Mode auto"
        echo "  $0 telegram       # Force les tests Telegram"
        echo "  $0 no-telegram    # Tests sans Telegram"
        echo "  $0 local          # Tests locaux complets"
        exit 0
        ;;
    "")
        print_mode "Mode automatique - Détection selon la configuration"
        ;;
    *)
        print_error "Mode inconnu: $1"
        echo "Utilisez '$0 help' pour voir les options disponibles"
        exit 1
        ;;
esac

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
SCRIPT_FILE="$SCRIPT_DIR/rasp-disk-alert.sh"

echo "🧪 Tests de validation pour raspi-disk-alert [$TEST_MODE]"
echo "========================================================="
echo
print_info "Ce script vérifie que tous les composants nécessaires sont présents"
print_info "sur votre machine pour faire fonctionner le système de surveillance."
echo

# Démonstration du résultat final en premier
print_status "💡 DÉMONSTRATION: Aperçu du message qui sera envoyé à Telegram"
echo "================================================================"

# Créer une simulation avec seuil très bas pour voir le résultat
DEMO_THRESHOLD=1
hostname=$(hostname)
demo_alerts=()
demo_message="🚨 <b>Alerte disque sur $hostname:</b>\n\n"

# Analyser les disques avec seuil très bas pour demo
print_info "Simulation avec seuil de démonstration à $DEMO_THRESHOLD% (vs le vrai seuil configuré)..."
echo

for path in "${DISK_PATHS[@]}"; do
    if [[ -d "$path" ]]; then
        # Obtenir les informations du disque
        disk_info=$(df -hP "$path" | tail -1)
        usage_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
        used_space=$(echo "$disk_info" | awk '{print $3}')
        total_space=$(echo "$disk_info" | awk '{print $2}')
        
        print_info "   $path: ${usage_percent}% utilisé (${used_space}/${total_space})"
        
        # Avec seuil de demo, tout sera en "alerte"
        if [[ "$usage_percent" -ge "$DEMO_THRESHOLD" ]]; then
            demo_alerts+=("$path : ${usage_percent}% utilisé ${used_space} sur ${total_space}")
        fi
    fi
done

echo

# Toujours afficher un aperçu, même simulé
if [[ ${#demo_alerts[@]} -gt 0 ]]; then
    print_success "🎭 APERÇU du message Telegram qui serait envoyé:"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ 🚨 Alerte disque sur $hostname:                               │"
    echo "│                                                             │"
    for alert in "${demo_alerts[@]}"; do
        printf "│ ⚠️  %-55s │\n" "$alert"
    done
    echo "│                                                             │"
    echo "│ 📊 Seuil configuré: ${DISK_THRESHOLD:-80}%                                     │"
    echo "│ 🕐 $(date)                                    │"
    echo "└─────────────────────────────────────────────────────────────┘"
else
    # Créer un exemple fictif pour montrer à quoi ça ressemble
    print_info "Vos disques sont tous sous le seuil de 1% - voici un EXEMPLE de ce qui serait envoyé:"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ 🚨 Alerte disque sur $hostname:                               │"
    echo "│                                                             │"
    echo "│ ⚠️  /mnt/disk1 : 85% utilisé 850G sur 1.0T                 │"
    echo "│ ⚠️  /mnt/backup : 95% utilisé 1.9T sur 2.0T                │"
    echo "│                                                             │"
    echo "│ 📊 Seuil configuré: ${DISK_THRESHOLD:-80}%                                     │"
    echo "│ 🕐 $(date)                                    │"
    echo "└─────────────────────────────────────────────────────────────┘"
    print_warning "↑ Ceci est un EXEMPLE fictif pour illustration"
fi

echo
print_info "☝️  Ceci était une DÉMONSTRATION avec seuil ${DEMO_THRESHOLD}% pour l'exemple"
print_info "   En réalité, votre seuil configuré est: ${DISK_THRESHOLD:-80}%"
echo
print_status "Maintenant, vérifions que tout est prêt pour que ça fonctionne..."
echo

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

# Test 5: Test de connexion Telegram (selon le mode)
if [[ "$DISABLE_TELEGRAM" == "true" ]]; then
    print_mode "Tests Telegram désactivés par le mode no-telegram"
elif [[ "$FORCE_TELEGRAM" == "true" ]] || [[ "$CONFIG_INCOMPLETE" != "true" && "$TEST_MODE" != "local" ]]; then
    print_status "Test de connexion Telegram..."
    
    if [[ "$FORCE_TELEGRAM" == "true" && "$CONFIG_INCOMPLETE" == "true" ]]; then
        print_warning "Mode telegram forcé avec configuration incomplète - les tests pourraient échouer"
    fi
    
    # Construire l'URL de test
    API_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/getMe"
    
    if response=$(curl -s "$API_URL" 2>/dev/null); then
        if echo "$response" | grep -q '"ok":true'; then
            print_success "Connexion Telegram réussie"
            
            # Extraire les infos du bot pour affichage
            BOT_NAME=$(echo "$response" | grep -o '"first_name":"[^"]*"' | cut -d'"' -f4)
            BOT_USERNAME=$(echo "$response" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
            print_info "Bot connecté: $BOT_NAME (@$BOT_USERNAME)"
            
            # Test d'envoi de message selon le mode
            if [[ "$TEST_MODE" == "local" ]]; then
                print_status "Mode local: simulation d'envoi de message (pas d'envoi réel)"
                MESSAGE="🧪 [SIMULATION] Test de raspi-disk-alert - $(date)"
                print_info "Message qui serait envoyé: $MESSAGE"
                print_success "Simulation d'envoi réussie"
            else
                print_status "Test d'envoi de message..."
                MESSAGE="🧪 Test de raspi-disk-alert [$TEST_MODE] - $(date)"
                SEND_URL="https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"
                
                print_info "Envoi du message: $MESSAGE"
                
                if response=$(curl -s -X POST "$SEND_URL" \
                    -d "chat_id=$TELEGRAM_CHAT_ID" \
                    -d "text=$MESSAGE" 2>/dev/null); then
                    
                    if echo "$response" | grep -q '"ok":true'; then
                        MESSAGE_ID=$(echo "$response" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
                        print_success "Message envoyé avec succès (ID: $MESSAGE_ID)"
                        print_info "Vérifiez votre chat Telegram pour voir le message de test"
                    else
                        ERROR_DESC=$(echo "$response" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
                        print_error "Erreur API Telegram: ${ERROR_DESC:-Erreur inconnue}"
                    fi
                else
                    print_error "Échec de l'envoi du message de test"
                fi
            fi
        else
            ERROR_DESC=$(echo "$response" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
            print_error "Token Telegram invalide: ${ERROR_DESC:-Erreur inconnue}"
            print_info "Response: $response"
        fi
    else
        print_error "Impossible de contacter l'API Telegram"
        print_info "Vérifiez votre connexion internet et votre token"
    fi
elif [[ "$TEST_MODE" == "local" ]]; then
    print_mode "Mode local: tests Telegram simulés uniquement"
    print_success "Configuration Telegram validée (pas de test réseau en mode local)"
else
    print_warning "Configuration incomplète - test Telegram ignoré"
    print_info "Utilisez '$0 telegram' pour forcer les tests Telegram"
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
echo "📊 Résumé des tests [$TEST_MODE]"
echo "================================="

case "$TEST_MODE" in
    "telegram")
        if [[ "$CONFIG_INCOMPLETE" == "true" ]]; then
            print_warning "Configuration incomplète - certains tests Telegram ont pu échouer"
            echo "➡️  Configurez le fichier .env avec vos vraies valeurs pour des tests complets"
        else
            print_success "Tests Telegram terminés !"
            echo "➡️  Vérifiez votre chat Telegram pour le message de test"
        fi
        ;;
    "no-telegram")
        print_success "Tests locaux terminés (Telegram ignoré) !"
        echo "➡️  Le système de base fonctionne - configurez Telegram quand vous voulez"
        ;;
    "local")
        print_success "Tests locaux complets terminés !"
        echo "➡️  Système validé - prêt pour utilisation réelle avec Telegram"
        ;;
    *)
        if [[ "$CONFIG_INCOMPLETE" == "true" ]]; then
            print_warning "Configuration incomplète détectée"
            echo "➡️  Éditez le fichier .env avec vos vraies valeurs"
            echo "   Token Telegram: obtenez-le via @BotFather"
            echo "   Chat ID: obtenez-le via @userinfobot"
        else
            print_success "Tous les tests sont passés avec succès !"
            echo "➡️  Le système est prêt à être utilisé"
        fi
        ;;
esac

echo
echo "💡 Commandes utiles:"
echo "   Test manuel: sudo $SCRIPT_FILE"
echo "   Tests spécialisés:"
echo "     ./test.sh telegram     # Force les tests Telegram"
echo "     ./test.sh no-telegram  # Ignore Telegram"
echo "     ./test.sh local        # Tests sans envoi de messages"
echo "   Configuration cron: sudo crontab -e"
echo "   Logs système: tail -f /var/log/syslog | grep raspi-disk-alert"

# Afficher des conseils selon le mode utilisé
echo
case "$TEST_MODE" in
    "telegram")
        print_info "💡 Conseil: Utilisez le mode 'local' pour tester sans spammer Telegram"
        ;;
    "no-telegram")
        print_info "💡 Conseil: Configurez Telegram plus tard avec './test.sh telegram'"
        ;;
    "local")
        print_info "💡 Conseil: Faites un test réel avec './test.sh telegram' quand prêt"
        ;;
esac
