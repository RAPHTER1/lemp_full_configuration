#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_FILE="$SCRIPT_DIR/logs/script.log"
CONFIG_FILE="$SCRIPT_DIR/config/settings.conf"
DB_CREDENTIALS="$SCRIPT_DIR/config/db_credentials.env"

source "$SCRIPT_DIR/functions/common.sh"
source "$SCRIPT_DIR/functions/packages.sh"
source "$SCRIPT_DIR/functions/php_config.sh"
source "$SCRIPT_DIR/functions/mariadb.sh"
source "$SCRIPT_DIR/functions/nginx.sh"
source "$SCRIPT_DIR/functions/prestashop.sh"
# source "$SCRIPT_DIR/functions/wordpress_install_config.sh"

#Vérifier si le fichier de configuration existe
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Fichier de configuration introuvable : $CONFIG_FILE"
    exit 1
fi

if [ -f "$DB_CREDENTIALS" ]; then
    source "$DB_CREDENTIALS"
else
    echo "Erreur : Fichier db_credentials.env introuvable."
    exit 1
fi

source "$CONFIG_FILE"

main() {
    log "Démarrage du script principal."

    check_root
    install_nginx
    install_mariadb
    configure_mariadb
    sudo mysql_secure_installation
    create_database_user
    install_packages
    configure_php
    # install_wordpress
    # configure_wordpress

    log "Script exécuté avec succès."
}

main

