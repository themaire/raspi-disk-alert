#!/bin/bash

# Récupérer le dossier du script (résout les liens symboliques)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"

# Charger le .env situé dans le même dossier que le script
source "$SCRIPT_DIR/.env"

# Mode démo
DEMO_MODE=false
if [[ "$1" == "--demo" ]]; then
    DEMO_MODE=true
    echo "🎭 MODE DÉMO - Simulation d'alertes avec données fictives"
    echo "======================================================="
fi

# Message initial
ALERT_MSG="Alerte disque sur $(hostname):"
SEND_ALERT=0

# Boucle sur les partitions
if [[ "$DEMO_MODE" == "true" ]]; then
    # Mode démo avec données fictives
    echo "📊 Données de démonstration :"
    
    # Partitions fictives pour la démo
    DEMO_PARTITIONS=(
        "/mnt/backup:95:1.8T:2.0T"
        "/mnt/storage:87:850G:1.0T"
        "/var/log:78:390M:500M"
        "/home:92:460G:500G"
    )
    
    for DEMO_DATA in "${DEMO_PARTITIONS[@]}"; do
        IFS=':' read -r PART USAGE_PCT USED SIZE <<< "$DEMO_DATA"
        echo "   $PART: ${USAGE_PCT}% utilisé ($USED/$SIZE)"
        
        if [ "$USAGE_PCT" -ge "$DISK_THRESHOLD" ]; then
            PART_MSG="$PART : $USAGE_PCT% utilise $USED sur $SIZE"
            ALERT_MSG+=$'\n'"$PART_MSG"
            SEND_ALERT=1
        fi
    done
    
    echo ""
    echo "🚨 Partitions dépassant le seuil de $DISK_THRESHOLD% :"
else
    # Mode normal avec vraies données
    for PART in "${DISK_PATHS[@]}"; do
        # Utiliser df -h pour format humain (Go, To, etc.)
        DF_OUTPUT=$(df -h "$PART" | awk 'NR==2')
        USAGE_PCT=$(echo "$DF_OUTPUT" | awk '{print $5}' | tr -d '%')
        USED=$(echo "$DF_OUTPUT" | awk '{print $3}')
        SIZE=$(echo "$DF_OUTPUT" | awk '{print $2}')

        if [ "$USAGE_PCT" -ge "$DISK_THRESHOLD" ]; then
            # Message simplifié pour éviter les problèmes MarkdownV2
            PART_MSG="$PART : $USAGE_PCT% utilise $USED sur $SIZE"
            ALERT_MSG+=$'\n'"$PART_MSG"
            SEND_ALERT=1
        fi
    done
fi

# Formatage du message avec bordure
format_alert_message() {
    local message="$1"
    local server_name=$(hostname)
    local current_date=$(date '+%d/%m/%Y à %H:%M:%S')
    
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│                      ALERTE DISQUE                         │"
    echo "│                                                             │"
    printf "│  Serveur : %-48s │\n" "$server_name"
    printf "│  Date    : %-48s │\n" "$current_date"
    echo "│                                                             │"
    printf "│  Partitions en alerte (seuil: %s%%) :%-19s │\n" "$DISK_THRESHOLD" ""
    echo "│                                                             │"
    
    # Afficher chaque partition en alerte
    echo "$message" | while IFS= read -r line; do
        if [[ -n "$line" && "$line" != "Alerte disque sur"* ]]; then
            printf "│  %-57s │\n" "$line"
        fi
    done
    
    echo "│                                                             │"
    echo "│  Action recommandée : Libérer de l'espace disque           │"
    echo "└─────────────────────────────────────────────────────────────┘"
}

# Envoi Telegram
if [ "$SEND_ALERT" -eq 1 ]; then
    # Créer le message formaté pour l'affichage
    FORMATTED_MSG=$(format_alert_message "$ALERT_MSG")
    
    if [[ "$DEMO_MODE" == "true" ]]; then
        echo "Message qui serait envoyé sur Telegram :"
        echo "$FORMATTED_MSG"
        echo ""
        echo "En mode normal, ce message serait envoyé à votre chat Telegram"
    else
        echo "Envoi de l'alerte sur Telegram..."
        echo "$FORMATTED_MSG"
        
        # Envoyer le message original (non formaté) sur Telegram pour compatibilité
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="$ALERT_MSG"
    fi
else
    if [[ "$DEMO_MODE" == "true" ]]; then
        echo "Aucune partition ne dépasse le seuil de $DISK_THRESHOLD%"
        echo "Pas d'alerte à envoyer"
    fi
fi