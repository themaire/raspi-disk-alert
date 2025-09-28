#!/bin/bash

# Script pour vérifier la configuration PATH après installation

echo "🔍 Vérification de la configuration PATH pour raspi-disk-alert"
echo "============================================================="

# Vérifier si /usr/local/bin est dans le PATH
if echo "$PATH" | grep -q "/usr/local/bin"; then
    echo "✅ /usr/local/bin est présent dans le PATH"
else
    echo "❌ /usr/local/bin n'est PAS dans le PATH"
    echo "💡 Ajoutez cette ligne à votre fichier de configuration shell :"
    echo "   export PATH=\"/usr/local/bin:\$PATH\""
    exit 1
fi

# Vérifier si le lien symbolique existe
if [[ -L "/usr/local/bin/raspi-disk-alert" ]]; then
    echo "✅ Lien symbolique raspi-disk-alert trouvé"
    TARGET=$(readlink "/usr/local/bin/raspi-disk-alert")
    echo "   → Pointe vers: $TARGET"
    
    if [[ -f "$TARGET" ]]; then
        echo "✅ Script cible trouvé et accessible"
    else
        echo "❌ Script cible introuvable : $TARGET"
        exit 1
    fi
else
    echo "❌ Lien symbolique raspi-disk-alert non trouvé"
    exit 1
fi

# Vérifier si la commande est accessible
if command -v raspi-disk-alert &> /dev/null; then
    echo "✅ Commande raspi-disk-alert accessible"
    echo "   Emplacement: $(which raspi-disk-alert)"
else
    echo "❌ Commande raspi-disk-alert non accessible"
    echo "💡 Essayez de redémarrer votre terminal ou exécutez :"
    echo "   source ~/.$(basename $SHELL)rc"
    exit 1
fi

# Vérifier les permissions
SCRIPT_PATH="/usr/local/bin/raspi-disk-alert"
if [[ -x "$SCRIPT_PATH" ]]; then
    echo "✅ Script exécutable"
else
    echo "❌ Script non exécutable"
    echo "💡 Exécutez: sudo chmod +x $SCRIPT_PATH"
    exit 1
fi

# Test de syntaxe (sans exécution)
echo
echo "🧪 Test de syntaxe du script..."
if bash -n "$SCRIPT_PATH"; then
    echo "✅ Syntaxe du script valide"
else
    echo "❌ Erreur de syntaxe dans le script"
    exit 1
fi

echo
echo "🎉 Configuration PATH validée avec succès !"
echo
echo "💡 Vous pouvez maintenant utiliser :"
echo "   - raspi-disk-alert --help"
echo "   - sudo raspi-disk-alert (pour l'exécution réelle)"
echo "   - sudo raspi-disk-alert --test (si supporté)"

# Afficher les informations shell
echo
echo "📋 Informations sur votre environnement :"
echo "   Shell actuel: $SHELL"
echo "   PATH: $PATH"
echo "   Utilisateur: $USER"