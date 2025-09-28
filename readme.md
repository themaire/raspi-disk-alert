# Surveillance Disque et Alertes Telegram

## Description

Ce projet permet de **surveiller l'utilisation de plusieurs partitions** et d'envoyer des alertes Telegram lorsque le seuil d'utilisation est dépassé.  

**Conçu initialement pour Raspberry Pi**, il est également **compatible avec macOS** et autres systèmes Unix/Linux.

Le projet utilise un **script Bash léger** avec un fichier `.env` pour stocker la configuration.

## Compatibilité

✅ **Raspberry Pi** (Raspbian/Debian/Ubuntu)  
✅ **macOS** (Monterey, Ventura, Sonoma...)  
✅ **Linux** (Ubuntu, Debian, CentOS, Arch...)  
✅ **Shells supportés** : Bash, Zsh, Fish

**Prérequis :** `curl` et `df` (installés par défaut sur la plupart des systèmes)

---

## Fonctionnement actuel

1. **Fichier `.env`** :

```bash
TELEGRAM_TOKEN="TON_TOKEN_BOT"
TELEGRAM_CHAT_ID="TON_CHAT_ID"
DISK_THRESHOLD=80
DISK_PATHS=(/ /mnt/partage_reseau /mnt/serveur_fbi /mnt/scanner /mnt/disque_externe_1)
```

2. **Script Bash `check_disk_alert.sh`** :
   - Boucle sur chaque partition dans `DISK_PATHS`
   - Vérifie l'utilisation avec `df -hP`
   - Construit un message avec les partitions dépassant le seuil
   - Envoie le message en texte brut sur Telegram via l'API

3. **Exécution** :

```bash
sudo /usr/local/bin/check_disk_alert.sh
```

   Le message Telegram ressemble à :
   
```text
Alerte disque sur ton_nom_de_serveur:
/mnt/serveur_fbi : 96% utilise 880G sur 917G
/mnt/scanner : 100% utilise 584G sur 587G
/mnt/disque_externe_1 : 100% utilise 1,9T sur 1,9T
```

- Peut être automatisé avec cron pour vérification régulière

---

## Difficultés rencontrées

1. **MarkdownV2 trop strict** :
   - Les caractères spéciaux (%, (, ), /, ,, etc.) et les accents provoquaient des erreurs
   - Les émojis et caractères Unicode pouvaient générer `$begin:math...$` ou simplement `*`
   - Solution temporaire : envoi en texte brut pour Telegram

2. **Problèmes avec Bash et tableaux** :
   - Mauvais line endings (CRLF) dans `.env` causaient `/\: Aucun fichier ou dossier de ce type`
   - Conversion en Unix line endings (`dos2unix`) nécessaire

3. **Échappement des caractères pour MarkdownV2** :
   - Même avec une fonction `escape_md2`, certains caractères comme `/` et `(` provoquaient des erreurs
   - Les accents sur "utilisé" ont également posé problème

---

## Points à améliorer pour plus tard

1. **Version MarkdownV2 robuste** :
   - Adapter le message pour que Telegram accepte tous les caractères spéciaux
   - Ajouter éventuellement des emojis pour indiquer l'état des partitions (⚠ pour critique, ✅ pour OK)
   - Tester sur des partitions avec `/` ou parenthèses dans les noms

2. **Support Unicode complet** :
   - Éviter les caractères problématiques (é, è, emojis complexes) ou les convertir avant en texte compatible MarkdownV2

3. **Notification consolidée** :
   - Afficher un indicateur visuel de saturation

4. **Historique et logging** :
   - Sauvegarder l'historique des alertes pour suivi
   - Possibilité de générer des graphiques ou de l'intégrer avec Prometheus/Grafana pour suivi à long terme

5. **Version Python (optionnelle)** :
   - Plus facile pour gérer MarkdownV2, Unicode, et échappements
   - Moins fragile que Bash pour les caractères spéciaux et l'Unicode

---

## Configuration

### Étape 1 : Créer un compte Telegram

Si vous n'avez pas encore de compte Telegram :

1. **Téléchargez Telegram** :
   - 📱 **Mobile** : [App Store](https://apps.apple.com/app/telegram-messenger/id686449807) ou [Google Play](https://play.google.com/store/apps/details?id=org.telegram.messenger)
   - 💻 **Desktop** : [telegram.org/desktop](https://desktop.telegram.org/)
   - 🌐 **Web** : [web.telegram.org](https://web.telegram.org/)

2. **Créez votre compte** avec votre numéro de téléphone
3. **Vérifiez** avec le code SMS reçu

### Étape 2 : Créer un bot Telegram avec BotFather

1. **Ouvrez Telegram** et recherchez `@BotFather` ou cliquez sur [@BotFather](https://t.me/BotFather)

2. **Démarrez une conversation** avec BotFather en cliquant sur "Démarrer" ou en tapant `/start`

3. **Créez un nouveau bot** :

   ```text
   /newbot
   ```

4. **Choisissez un nom** pour votre bot (ex: "Mon Surveillant Disque")

5. **Choisissez un nom d'utilisateur** unique se terminant par "bot" (ex: `mon_disk_alert_bot`)

6. **Récupérez votre token** : BotFather vous donnera un token qui ressemble à :

   ```text
   123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```

   ⚠️ **Gardez ce token secret !**

### Étape 3 : Obtenir votre Chat ID

**Méthode 1 (la plus simple) :**

1. Recherchez `@userinfobot` ou cliquez sur [@userinfobot](https://t.me/userinfobot)
2. Démarrez une conversation avec `/start`
3. Il vous donnera votre Chat ID (un nombre comme `123456789`)

**Méthode 2 (avec votre bot) :**

1. **Recherchez votre bot** dans Telegram (avec le nom d'utilisateur choisi)
2. **Envoyez un message** à votre bot (ex: "Hello")
3. **Ouvrez cette URL** dans votre navigateur :

   ```text
   https://api.telegram.org/bot<VOTRE_TOKEN>/getUpdates
   ```

   (Remplacez `<VOTRE_TOKEN>` par votre token)
4. **Trouvez votre Chat ID** dans la réponse JSON :

   ```json
   "chat":{"id":123456789,"first_name":"Votre Nom"...}
   ```

---

## Installation

### Installation automatique (recommandée)

1. Cloner le projet :

```bash
git clone https://github.com/votre-username/raspi-disk-alert.git
cd raspi-disk-alert
```

2. Lancer l'installation automatique :

```bash
sudo ./install.sh
```

   L'installation configurera automatiquement :

- ✅ Installation dans `/usr/local/bin/raspi-disk-alert/`
- ✅ Lien symbolique dans `/usr/local/bin/`
- ✅ Configuration du PATH selon votre shell (zsh, bash, fish, etc.)
- ✅ Permissions sécurisées
- ✅ Script de désinstallation

3. Redémarrer votre terminal ou recharger la configuration :

```bash
# Pour Zsh
source ~/.zshrc

# Pour Bash
source ~/.bashrc

# Ou simplement redémarrer le terminal
```

4. Configurer vos paramètres :

```bash
sudo nano /usr/local/bin/raspi-disk-alert/.env
```

5. Tester l'installation :

```bash
sudo ./test.sh
```

### Installation manuelle

Si vous préférez installer manuellement :

1. Créer le répertoire d'installation :

```bash
sudo mkdir -p /usr/local/bin/raspi-disk-alert
```

2. Copier les fichiers :

```bash
sudo cp rasp-disk-alert.sh .env.example /usr/local/bin/raspi-disk-alert/
sudo cp .env.example /usr/local/bin/raspi-disk-alert/.env
```

3. Configurer les permissions :

```bash
sudo chmod +x /usr/local/bin/raspi-disk-alert/rasp-disk-alert.sh
sudo chmod 600 /usr/local/bin/raspi-disk-alert/.env
```

4. Créer le lien symbolique :

```bash
sudo ln -sf /usr/local/bin/raspi-disk-alert/rasp-disk-alert.sh /usr/local/bin/raspi-disk-alert
```

---

## Démonstration

### Script de démonstration

Un script `demo.sh` est fourni pour présenter le projet et simuler une sortie d'alerte :

```bash
./demo.sh
```

Ce script affiche :

- 📁 **Structure du projet** avec la liste des fichiers
- ⚙️ **Configuration d'exemple** (contenu de `.env.example`)
- 🔧 **Permissions des scripts** pour vérifier l'exécutabilité
- 💡 **Commandes d'utilisation** typiques avec exemples
- 📊 **Simulation d'alerte** avec un exemple formaté d'alerte Telegram

### Mode démonstration du script principal

Le script principal supporte également un mode démonstration :

```bash
# Test local
./rasp-disk-alert.sh --demo

# Après installation
sudo raspi-disk-alert --demo
```

Ce mode simule une alerte avec des données fictives pour tester le formatage sans avoir besoin de disques réellement pleins.

---

## Tests et validation

### Script de test automatique

Un script de test est fourni pour valider votre installation :

```bash
sudo ./test.sh
```

Ce script vérifie :

- ✅ Présence des fichiers requis
- ✅ Permissions correctes
- ✅ Validité de la configuration
- ✅ Dépendances système (curl, df)
- ✅ Connexion Telegram
- ✅ Envoi d'un message de test

### Utilisation après installation

Après l'installation, vous pouvez utiliser le script de plusieurs façons :

```bash
# Via le lien symbolique (recommandé)
sudo raspi-disk-alert

# Via le chemin complet
sudo /usr/local/bin/raspi-disk-alert

# Si votre PATH a été configuré correctement (sans sudo pour les tests)
raspi-disk-alert --help
```

### Tests manuels

1. **Test de base** :

```bash
sudo raspi-disk-alert
```

2. **Test avec debug** (si supporté par votre script) :

```bash
sudo raspi-disk-alert --debug
```

3. **Vérifier les logs système** :

```bash
tail -f /var/log/syslog | grep raspi-disk-alert
```

---

## Configuration du Cron

### Automatisation recommandée

Pour surveiller vos disques automatiquement, configurez une tâche cron :

```bash
sudo crontab -e
```

### Exemples de configuration

```cron
# Vérification toutes les heures
0 * * * * /usr/local/bin/raspi-disk-alert

# Vérification toutes les 30 minutes
*/30 * * * * /usr/local/bin/raspi-disk-alert

# Vérification tous les jours à 8h et 20h
0 8,20 * * * /usr/local/bin/raspi-disk-alert

# Vérification toutes les 15 minutes pendant les heures de bureau
*/15 8-18 * * 1-5 /usr/local/bin/raspi-disk-alert
```

### Gestion des logs avec cron

Pour éviter l'accumulation de logs, redirigez la sortie :

```cron
# Avec logs dans un fichier dédié
0 * * * * /usr/local/bin/raspi-disk-alert >> /var/log/raspi-disk-alert.log 2>&1

# Sans logs (silencieux)
0 * * * * /usr/local/bin/raspi-disk-alert >/dev/null 2>&1

# Avec rotation des logs (recommandé)
0 * * * * /usr/local/bin/raspi-disk-alert >> /var/log/raspi-disk-alert.log 2>&1 && find /var/log -name "raspi-disk-alert.log" -size +10M -exec truncate -s 0 {} \;
```

### Vérifier les tâches cron

```bash
# Lister les tâches cron actives
sudo crontab -l

# Vérifier les logs de cron
sudo tail -f /var/log/cron.log

# Vérifier l'exécution (sur certains systèmes)
sudo journalctl -u cron -f
```

---

## Désinstallation

Pour désinstaller proprement le système :

```bash
sudo /usr/local/bin/uninstall-raspi-disk-alert.sh
```

Le script de désinstallation :

- 🗑️ Supprime tous les fichiers installés
- ⚙️ Propose de conserver la configuration
- 📅 Propose de supprimer les tâches cron
- 🧹 Se supprime automatiquement après exécution

---

## Remarques finales

- Le projet fonctionne actuellement en texte brut pour Telegram et est fiable
- Les améliorations MarkdownV2 et emojis peuvent être implémentées plus tard, une fois que les caractères spéciaux sont correctement gérés
- Projet léger, facile à maintenir et à étendre pour de nouvelles partitions ou des alertes supplémentaires

---

## Future Improvements

- Ajouter MarkdownV2 avec emojis pour chaque partition (⚠ pour critique, ✅ pour OK)
- Support complet des caractères Unicode et accents dans les messages
- Gestion avancée des notifications : regrouper toutes les partitions dans un seul message avec un format clair
- Historique des alertes et génération de graphiques pour suivi de la saturation disque
- Version Python pour faciliter l'échappement MarkdownV2 et Unicode
- Intégration avec des outils de monitoring comme Grafana/Prometheus pour un suivi temps réel
