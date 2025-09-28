#!/bin/bash

# Script d'installation pour raspi-disk-alert
# Ce script installe le projet dans /usr/local/bin/raspi-disk-alert/

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les permissions root
if [[ $EUID -ne 0 ]]; then
   print_error "Ce script doit être exécuté en tant que root (utilisez sudo)"
   exit 1
fi

# Variables
INSTALL_DIR="/usr/local/bin/raspi-disk-alert"
SCRIPT_NAME="rasp-disk-alert.sh"
UNINSTALL_SCRIPT="/usr/local/bin/uninstall-raspi-disk-alert.sh"

print_status "Installation de raspi-disk-alert..."

# Créer le répertoire d'installation
print_status "Création du répertoire d'installation: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copier les fichiers
print_status "Copie des fichiers..."
cp "$SCRIPT_NAME" "$INSTALL_DIR/"
cp ".env.example" "$INSTALL_DIR/"

# Vérifier si .env existe déjà
if [[ -f "$INSTALL_DIR/.env" ]]; then
    print_warning "Le fichier .env existe déjà, il ne sera pas écrasé"
else
    if [[ -f ".env" ]]; then
        print_status "Copie du fichier .env existant..."
        cp ".env" "$INSTALL_DIR/"
    else
        print_status "Création du fichier .env à partir du template..."
        cp ".env.example" "$INSTALL_DIR/.env"
        print_warning "N'oubliez pas de configurer le fichier .env avec vos vraies valeurs !"
    fi
fi

# Rendre le script exécutable
print_status "Configuration des permissions..."
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
chmod 600 "$INSTALL_DIR/.env"  # Permissions restreintes pour le fichier de configuration

# Créer un lien symbolique pour faciliter l'exécution
print_status "Création du lien symbolique..."
ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "/usr/local/bin/raspi-disk-alert"

# Ajouter au PATH si nécessaire
add_to_path() {
    local shell_rc="$1"
    local path_line='export PATH="/usr/local/bin:$PATH"'
    
    if [[ -f "$shell_rc" ]]; then
        if ! grep -q "/usr/local/bin" "$shell_rc"; then
            print_status "Ajout de /usr/local/bin au PATH dans $shell_rc"
            echo "" >> "$shell_rc"
            echo "# Ajouté par raspi-disk-alert installer" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            return 0
        else
            print_status "/usr/local/bin déjà présent dans $shell_rc"
            return 1
        fi
    fi
    return 1
}

# Détecter et configurer le shell de l'utilisateur réel (pas root)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

if [[ -n "$REAL_USER" && "$REAL_USER" != "root" ]]; then
    print_status "Configuration du PATH pour l'utilisateur: $REAL_USER"
    
    # Détecter le shell par défaut de l'utilisateur
    USER_SHELL=$(getent passwd "$REAL_USER" | cut -d: -f7)
    SHELL_NAME=$(basename "$USER_SHELL")
    
    PATH_ADDED=false
    
    case "$SHELL_NAME" in
        "zsh")
            print_status "Shell détecté: Zsh"
            if add_to_path "$REAL_HOME/.zshrc"; then
                PATH_ADDED=true
                print_success "PATH ajouté à ~/.zshrc"
            fi
            ;;
        "bash")
            print_status "Shell détecté: Bash"
            # Essayer .bashrc en premier, puis .bash_profile
            if add_to_path "$REAL_HOME/.bashrc"; then
                PATH_ADDED=true
                print_success "PATH ajouté à ~/.bashrc"
            elif add_to_path "$REAL_HOME/.bash_profile"; then
                PATH_ADDED=true
                print_success "PATH ajouté à ~/.bash_profile"
            fi
            ;;
        "fish")
            print_status "Shell détecté: Fish"
            FISH_CONFIG="$REAL_HOME/.config/fish/config.fish"
            if [[ -f "$FISH_CONFIG" ]] && ! grep -q "/usr/local/bin" "$FISH_CONFIG"; then
                echo "" >> "$FISH_CONFIG"
                echo "# Ajouté par raspi-disk-alert installer" >> "$FISH_CONFIG"
                echo "set -gx PATH /usr/local/bin \$PATH" >> "$FISH_CONFIG"
                PATH_ADDED=true
                print_success "PATH ajouté à ~/.config/fish/config.fish"
            fi
            ;;
        *)
            print_warning "Shell non reconnu: $SHELL_NAME"
            print_status "Tentative avec .profile..."
            if add_to_path "$REAL_HOME/.profile"; then
                PATH_ADDED=true
                print_success "PATH ajouté à ~/.profile"
            fi
            ;;
    esac
    
    if [[ "$PATH_ADDED" == "true" ]]; then
        print_success "Configuration PATH terminée !"
        print_status "Redémarrez votre terminal ou exécutez: source ~/${SHELL_NAME}rc"
        print_status "Vous pourrez ensuite utiliser: raspi-disk-alert (sans sudo pour les tests)"
    else
        print_warning "Impossible d'ajouter automatiquement au PATH"
        print_status "Ajoutez manuellement cette ligne à votre fichier de config shell:"
        echo "export PATH=\"/usr/local/bin:\$PATH\""
    fi
else
    print_warning "Utilisateur réel non détecté, configuration PATH ignorée"
fi

# Créer le script de désinstallation
print_status "Création du script de désinstallation..."
cat > "$UNINSTALL_SCRIPT" << 'EOF'
#!/bin/bash

# Script de désinstallation pour raspi-disk-alert

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les permissions root
if [[ $EUID -ne 0 ]]; then
   print_error "Ce script doit être exécuté en tant que root (utilisez sudo)"
   exit 1
fi

INSTALL_DIR="/usr/local/bin/raspi-disk-alert"

print_status "Désinstallation de raspi-disk-alert..."

# Supprimer le lien symbolique
if [[ -L "/usr/local/bin/raspi-disk-alert" ]]; then
    print_status "Suppression du lien symbolique..."
    rm -f "/usr/local/bin/raspi-disk-alert"
fi

# Demander si on garde la configuration
if [[ -f "$INSTALL_DIR/.env" ]]; then
    echo
    read -p "Voulez-vous conserver le fichier de configuration .env ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        KEEP_CONFIG=false
    else
        KEEP_CONFIG=true
        print_warning "Le fichier de configuration sera conservé dans: $INSTALL_DIR/.env"
    fi
else
    KEEP_CONFIG=false
fi

# Supprimer le répertoire d'installation
if [[ -d "$INSTALL_DIR" ]]; then
    if [[ "$KEEP_CONFIG" == "true" ]]; then
        print_status "Suppression des fichiers (sauf .env)..."
        find "$INSTALL_DIR" -type f ! -name ".env" -delete
        find "$INSTALL_DIR" -type d -empty -delete 2>/dev/null || true
    else
        print_status "Suppression complète du répertoire d'installation..."
        rm -rf "$INSTALL_DIR"
    fi
fi

# Supprimer les modifications PATH (optionnel)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

if [[ -n "$REAL_USER" && "$REAL_USER" != "root" ]]; then
    echo
    read -p "Voulez-vous supprimer les modifications PATH des fichiers de config shell ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Suppression des modifications PATH..."
        
        # Liste des fichiers à vérifier
        CONFIG_FILES=(
            "$REAL_HOME/.zshrc"
            "$REAL_HOME/.bashrc" 
            "$REAL_HOME/.bash_profile"
            "$REAL_HOME/.profile"
            "$REAL_HOME/.config/fish/config.fish"
        )
        
        for config_file in "${CONFIG_FILES[@]}"; do
            if [[ -f "$config_file" ]] && grep -q "raspi-disk-alert installer" "$config_file"; then
                print_status "Nettoyage de $config_file"
                # Supprimer la ligne de commentaire et la ligne PATH ajoutées
                sed -i.bak '/# Ajouté par raspi-disk-alert installer/,+1d' "$config_file"
                # Supprimer les lignes vides en fin de fichier si elles ont été ajoutées
                sed -i.bak -e :a -e '/^\s*$/N; ba; s/\n$//; s/\n\s*$/\n/' "$config_file"
                rm -f "$config_file.bak"
            fi
        done
        
        print_success "Modifications PATH supprimées"
        print_warning "Redémarrez votre terminal pour appliquer les changements"
    fi
fi

# Supprimer les tâches cron (optionnel)
echo
read -p "Voulez-vous supprimer les tâches cron associées ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Suppression des tâches cron..."
    # Supprimer les lignes contenant raspi-disk-alert du crontab
    (crontab -l 2>/dev/null | grep -v "raspi-disk-alert" | crontab -) || print_warning "Aucune tâche cron trouvée"
fi

print_success "Désinstallation terminée !"

# Auto-suppression du script de désinstallation
print_status "Suppression du script de désinstallation..."
rm -f "$0"

EOF

chmod +x "$UNINSTALL_SCRIPT"

# Tester la configuration si .env est configuré
print_status "Test de la configuration..."
if [[ -f "$INSTALL_DIR/.env" ]]; then
    source "$INSTALL_DIR/.env"
    if [[ "$TELEGRAM_TOKEN" != *"VOTRE_TOKEN"* && "$TELEGRAM_CHAT_ID" != *"VOTRE_CHAT"* ]]; then
        print_status "Test d'envoi d'un message de test..."
        if "$INSTALL_DIR/$SCRIPT_NAME" --test 2>/dev/null; then
            print_success "Test réussi ! Le bot fonctionne correctement."
        else
            print_warning "Le test a échoué. Vérifiez votre configuration dans $INSTALL_DIR/.env"
        fi
    else
        print_warning "Configuration non complétée. Éditez $INSTALL_DIR/.env avec vos vraies valeurs."
    fi
fi

print_success "Installation terminée !"
echo
echo "📍 Emplacement d'installation: $INSTALL_DIR"
echo "🔧 Configuration: $INSTALL_DIR/.env"
echo "🚀 Commande: raspi-disk-alert"
echo "🗑️  Désinstallation: sudo $UNINSTALL_SCRIPT"
echo
print_status "Prochaines étapes:"
echo "1. Éditez la configuration: sudo nano $INSTALL_DIR/.env"
if [[ "$PATH_ADDED" == "true" ]]; then
    echo "2. Redémarrez votre terminal ou exécutez: source ~/.${SHELL_NAME}rc"
    echo "3. Testez le script: raspi-disk-alert (ou sudo raspi-disk-alert)"
    echo "4. Configurez le cron: sudo crontab -e"
else
    echo "2. Testez le script: sudo raspi-disk-alert"
    echo "3. Configurez le cron: sudo crontab -e"
fi
echo "   Ajoutez: 0 * * * * /usr/local/bin/raspi-disk-alert"
