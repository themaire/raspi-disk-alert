#!/bin/bash

# Script de démonstration pour raspi-disk-alert
# Simule un environnement de test

echo "🚀 Démonstration de raspi-disk-alert"
echo "===================================="
echo

# Afficher la structure du projet
echo "📁 Structure du projet:"
ls -la
echo

# Afficher le contenu du fichier .env.example
echo "⚙️ Configuration d'exemple (.env.example):"
echo "----------------------------------------"
cat .env.example
echo

# Vérifier si les scripts sont exécutables
echo "🔧 Vérification des permissions:"
echo "--------------------------------"
echo "install.sh: $(ls -l install.sh | cut -d' ' -f1)"
echo "test.sh: $(ls -l test.sh | cut -d' ' -f1)"
echo "rasp-disk-alert.sh: $(ls -l rasp-disk-alert.sh | cut -d' ' -f1)"
echo

# Simuler l'utilisation du système
echo "💡 Commandes d'utilisation typiques:"
echo "-----------------------------------"
echo "1. Installation:     sudo ./install.sh"
echo "2. Configuration:    sudo nano /usr/local/bin/raspi-disk-alert/.env"
echo "3. Test:             sudo ./test.sh"
echo "4. Exécution:        sudo raspi-disk-alert"
echo "5. Cron:             sudo crontab -e"
echo "6. Désinstallation:  sudo /usr/local/bin/uninstall-raspi-disk-alert.sh"
echo

echo "✨ Projet prêt pour le déploiement !"
echo "   - Installation automatique ✅"
echo "   - Tests de validation ✅"
echo "   - Désinstallation propre ✅"
echo "   - Documentation complète ✅"
echo "   - Sécurité (.env ignoré) ✅"
