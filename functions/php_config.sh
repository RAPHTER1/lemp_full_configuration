#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

configure_php() {
    # Détection de la version de php qui a été installé
    local php_version=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    log "La version $php_version de PHP est installé sur la machine."

    php_ini_file="/etc/php/$php_version/fpm/php.ini"

    # Vérification si php.ini existe
    if [ ! -f "$php_ini_file" ]; then
        log "Le fichier de paramètres PHP est introuvable : $php_ini_file"
        exit 1
    fi

    # Mise à jour du fichier php.ini
    for setting in "${PHP_SETTINGS[@]}"; do
        if [[ "$setting" != *"="* ]]; then
            echo "$CONFIG_FILE : le paramètre '$setting' doit être sous la forme key = value."
            exit 1
        else
            key=$(echo "$setting" | cut -d '=' -f1 | xargs)
            value=$(echo "$setting" | cut -d '=' -f2 | xargs)
            sed -i "s/^${key}\\s*=.*/${key} = ${value}/" "$php_ini_file"
            log "$php_ini_file : $key = $value"
        fi
    done

    sudo systemctl restart php${php_version}-fpm
}