#!/bin/bash

# Configuration
readonly DATE=$(date '+%F')
readonly DB_NAME="prestashop"
readonly WEBSITE_DIR="/var/www"
readonly WEBSITE_NAME="prestashop"
readonly BASE_DIR="/var/backups/prestashop"
readonly BACKUP_DIR="backup-$DATE"
readonly DB_BACKUP_FILE="database-$DATE.sql"
readonly WEBSITE_BACKUP_FILE="$WEBSITE_NAME-$DATE.tar.gz"
readonly LOG_FILE="backup-$DATE.log"
readonly BUCKET_NAME="prestashop-backups"
readonly FINAL_BACKUP_FILE="$BASE_DIR/$BACKUP_DIR.tar.gz"

# Fonction de logging améliorée
log() {
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$current_time] $1"
    echo "$message"
    if [[ -n "$LOG_FILE_PATH" ]]; then
        echo "$message" >> "$LOG_FILE_PATH"
    fi
}

# Fonction de gestion d'erreur
handle_error() {
    local error_message="$1"
    log "ERREUR: $error_message"
    exit 1
}

database_backup() {
    log "Sauvegarde de la base de données..."
    if ! mysqldump --defaults-file=/home/backup_user/.my.cnf "$DB_NAME" > "$BASE_DIR/$BACKUP_DIR/$DB_BACKUP_FILE"; then
        handle_error "Échec de la sauvegarde de la base de données"
    fi
    log "Sauvegarde de la base de données terminée : $DB_BACKUP_FILE"
}

website_backup() {
    log "Sauvegarde des fichiers du site..."
    if ! tar -czpf "$BASE_DIR/$BACKUP_DIR/$WEBSITE_BACKUP_FILE" -C "$WEBSITE_DIR" "$WEBSITE_NAME"; then
        handle_error "Échec de la sauvegarde des fichiers du site"
    fi
    log "Sauvegarde des fichiers du site terminée : $WEBSITE_BACKUP_FILE"
}

bucket_push() {
    log "Préparation de la copie sur le cloud AWS S3-$BUCKET_NAME..."
    
    # Compression du dossier de sauvegarde complet
    if ! tar -czpf "$FINAL_BACKUP_FILE" -C "$BASE_DIR" "$BACKUP_DIR/"; then
        handle_error "Échec de la compression du dossier de sauvegarde complet"
    fi
    log "Compression du dossier de sauvegarde terminée : $FINAL_BACKUP_FILE"
    
    # Vérification de la connexion AWS avant l'upload
    if ! aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
        handle_error "Impossible d'accéder au bucket S3 $BUCKET_NAME"
    fi
    
    # Upload vers S3
    if ! aws s3 cp "$FINAL_BACKUP_FILE" "s3://$BUCKET_NAME/"; then
        handle_error "Échec de l'upload vers S3"
    fi
    log "Copie sur le cloud AWS S3-$BUCKET_NAME réalisée avec succès"
    
    # Nettoyage des fichiers locaux
    log "Suppression du fichier local de sauvegarde..."
    rm -f "$FINAL_BACKUP_FILE"
    log "Fichier local supprimé : $FINAL_BACKUP_FILE"
}

cleanup_old_backups() {
    # Garde uniquement les 7 dernières sauvegardes sur S3
    log "Nettoyage des anciennes sauvegardes..."
    local backup_count=$(aws s3 ls "s3://$BUCKET_NAME/" | wc -l)
    if [[ $backup_count -gt 7 ]]; then
        aws s3 ls "s3://$BUCKET_NAME/" | sort | head -n -7 | while read -r line; do
            local file=$(echo "$line" | awk '{print $4}')
            aws s3 rm "s3://$BUCKET_NAME/$file"
            log "Ancienne sauvegarde supprimée : $file"
        done
    fi
}

main() {
    # Vérification des prérequis
    [[ -d "$WEBSITE_DIR" ]] || handle_error "Répertoire du site web introuvable"
    [[ -f "/home/backup_user/.my.cnf" ]] || handle_error "Fichier de configuration MySQL introuvable"
    
    # Création du répertoire de sauvegarde
    mkdir -p "$BASE_DIR/$BACKUP_DIR" || handle_error "Impossible de créer le répertoire de sauvegarde"
    
    # Configuration du fichier de log
    readonly LOG_FILE_PATH="$BASE_DIR/$BACKUP_DIR/$LOG_FILE"
    exec > >(tee -a "$LOG_FILE_PATH") 2>&1
    
    log "Début de la sauvegarde..."
    database_backup
    website_backup
    bucket_push
    cleanup_old_backups
    log "Fin de la sauvegarde."
}

# Gestion des erreurs globales
set -euo pipefail
trap 'handle_error "Une erreur inattendue est survenue"' ERR

main
