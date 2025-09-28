#!/bin/bash

# Script de démonstration des modes de test pour raspi-disk-alert

echo "🎭 Démonstration des modes de test raspi-disk-alert"
echo "=================================================="
echo

# Couleurs
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_demo() {
    echo -e "${BLUE}[DEMO]${NC} $1"
}

print_command() {
    echo -e "${GREEN}➜${NC} $1"
}

print_note() {
    echo -e "${YELLOW}💡${NC} $1"
}

print_demo "Voici les différents modes de test disponibles :"
echo

echo "1. 🔧 Mode automatique (par défaut)"
print_command "./test.sh"
print_note "Détecte automatiquement si la configuration est complète"
print_note "Teste Telegram seulement si token et chat ID sont configurés"
echo

echo "2. 📱 Mode Telegram forcé"
print_command "./test.sh telegram"
print_note "Force les tests Telegram même avec configuration incomplète"
print_note "Utile pour tester vos tokens pendant la configuration"
print_note "ENVOIE UN VRAI MESSAGE à votre chat Telegram !"
echo

echo "3. 🚫 Mode sans Telegram"
print_command "./test.sh no-telegram"
print_note "Ignore complètement tous les tests Telegram"
print_note "Parfait pour tester le système de base sans configuration Telegram"
print_note "Idéal pour la phase de développement/installation"
echo

echo "4. 🏠 Mode local"
print_command "./test.sh local"
print_note "Tests complets MAIS simule l'envoi de messages (pas d'envoi réel)"
print_note "Vérifie la connexion Telegram sans spammer votre chat"
print_note "Parfait pour valider la config sans polluer Telegram"
echo

echo "5. ❓ Aide"
print_command "./test.sh help"
print_note "Affiche l'aide complète avec tous les modes"
echo

print_demo "Cas d'usage typiques :"
echo

echo "🔧 Pendant l'installation :"
print_command "sudo ./install.sh"
print_command "./test.sh no-telegram    # Tester le système de base"
echo

echo "⚙️ Pendant la configuration Telegram :"
print_command "sudo nano /usr/local/bin/raspi-disk-alert/.env"
print_command "./test.sh local          # Vérifier sans envoyer de messages"
print_command "./test.sh telegram       # Test réel avec envoi de message"
echo

echo "🚀 En production :"
print_command "./test.sh                # Mode auto pour validation complète"
echo

print_demo "Le script détecte automatiquement :"
echo "   ✅ Présence et permissions des fichiers"
echo "   ✅ Validité de la configuration .env"
echo "   ✅ Dépendances système (curl, df)"
echo "   ✅ Connexion et authentification Telegram"
echo "   ✅ Capacité d'envoi de messages"
echo

print_note "Astuce: Utilisez le mode 'local' pour développer sans spammer Telegram !"
print_note "Le mode 'telegram' envoie de VRAIS messages - à utiliser avec parcimonie !"