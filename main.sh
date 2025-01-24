#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_FILE="$SCRIPT_DIR/logs/script.log"
CONFIG_FILE="$SCRIPT_DIR/config/settings.conf"

source "$SCRIPT_DIR/functions/common.sh"
source "$SCRIPT_DIR/functions/packages.sh"
source "$SCRIPT_DIR/functions/php_configuration.sh"

main() {
    check_root
}


# Détection de la version de php qui a été installé
php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

if [ -z "$php_version" ]; then
    date_log "Impossible de detecté la version de PHP." | tee -a script.log
    exit 1
fi

# Vérification de la présence du fichier php.ini
php_ini_file="/etc/php/${php_version}/fpm/php.ini"

if [ ! -f "$php_ini_file" ]; then
    date_log "Fichier de configuration introuvable : $php_ini_file" | tee -a script.log
    exit 1
fi

# Récupération des réglages PHP"
declare -A php_settings
if [ -f "$php_settings_file" ]; then
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        php_settings["$key"]="$value"
    done < "$php_settings_file"
else
    date_log "Le fichier de paramètres PHP introuvable : $php_settings_file" | tee -a script.log
    exit 1
fi

# Modification du fichier php.ini
date_log "Modification du fichier de configuration: $php_ini_file" | tee -a script.log

for key in "${php_settings[@]}"; do
    sed -i "s/^${key}\\s*=.*/${key} = ${php_settings[$key]}/" "$php_ini_file"
done


date_log "Configuration mise à jour avec succès." | tee -a script.log

sudo systemctl restart php${php_version}-fpm

wp_install_folder="/var/www/html/"

if  [ ! -d "${wp_install_folder}wordpress" ]; then
    echo "Le dossier Wordpress n'existe pas."
    if [ ! -f "${wp_install_folder}latest.tar.gz" ]; then
        echo "Téléchargement de Wordpress en cours ..."
        wget https://wordpress.org/latest.tar.gz
        tar -zxvf ${wp_install_folder}latest.tar.gz
        echo "Installation de WordPress a été complété avec succès."
    else
        tar -zxvf ${wp_install_folder}latest.tar.gz
        echo "Installation de WordPress a été complété avec succès."
    fi
fi

if [ ! -f "/var/www/html/wordpress/wp-config.php" ];then
    echo "File does not exists ${wp_install_folder}"
    mv ${wp_install_folder}wordpress/wp-config-sample.php ${wp_install_folder}wordpress/wp-config.php
fi

config_file="$SCRIPT_DIR/settings.conf"

source $config_file
for setting in ${database_settings[@]};do
    key=$(echo "$setting" | cut -d'=' -f1)
    value=$(echo "$setting" | cut -d'=' -f2)
    echo "Configuration : $key = $value"
    sed -i "s/^define(\\s*'${key}'\\s*,\\s*'.*'\\s*)\\s*;/define( '${key}', '${value}' );/" "${wp_install_folder}wordpress/wp-config.php"
    done


