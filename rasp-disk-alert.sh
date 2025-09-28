#!/bin/bash

# Récupérer le dossier du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Charger le .env situé dans le même dossier que le script
source "$SCRIPT_DIR/.env"

# Message initial
ALERT_MSG="Alerte disque sur $(hostname):"
SEND_ALERT=0

# Boucle sur les partitions
for PART in "${DISK_PATHS[@]}"; do
    USAGE_PCT=$(df -hP "$PART" | awk 'NR==2 {print $5}' | tr -d '%')
    USED=$(df -hP "$PART" | awk 'NR==2 {print $3}')
    SIZE=$(df -hP "$PART" | awk 'NR==2 {print $2}')

    if [ "$USAGE_PCT" -ge "$DISK_THRESHOLD" ]; then
        # Message simplifié pour éviter les problèmes MarkdownV2
        PART_MSG="$PART : $USAGE_PCT% utilise $USED sur $SIZE"
        ALERT_MSG+=$'\n'"$PART_MSG"
        SEND_ALERT=1
    fi
done

# Envoi Telegram
if [ "$SEND_ALERT" -eq 1 ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$ALERT_MSG"
fi