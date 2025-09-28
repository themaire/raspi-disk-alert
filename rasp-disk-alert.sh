#!/bin/bash

# Récupérer le dossier du script (résout les liens symboliques)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"

# Charger le .env situé dans le même dossier que le script
source "$SCRIPT_DIR/.env"

# Message initial
ALERT_MSG="Alerte disque sur $(hostname):"
SEND_ALERT=0

# Boucle sur les partitions
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

# Envoi Telegram
if [ "$SEND_ALERT" -eq 1 ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$ALERT_MSG"
fi