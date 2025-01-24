#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

install_wordpress() {
    log "Début de l'installation de WordPress."

    local wp_folder="/var/www/html/wordpress"

     if [ ! -d "$wp_folder" ]; then
        wget -q -O /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
        tar -xzf /tmp/latest.tar.gz -C /var/www/html/
        log "WordPress installé dans $wp_folder."
    else
        log "WordPress est déjà installé."
    fi
}

configure_wordpress() {
    log "Début de la configuration de WordPress."

    local wp_config="/var/www/html/wordpress/wp-config.php"

    if [ ! -f "$wp_config" ]; then
        cp /var/www/html/wordpress/wp-config-sample.php "$wp_config"
        log "Fichier de configuration copié dans $wp_config."
    fi

    for setting in "${WORDPRESS_SETTINGS[@]}"; do
        if [[ "$setting" != *"="* ]]; then
            echo "$CONFIG_FILE : le paramètre '$setting' doit être sous la forme key = value."
            exit 1
        else
            key=$(echo "$setting" | cut -d '=' -f1 | xargs)
            value=$(echo "$setting" | cut -d '=' -f2 | xargs)
            sed -i "s/^define(\\s*'${key}'\\s*,\\s*'.*'\\s*)\\s*;/define( '${key}', '${value}' );/" "$wp_config"
            log "$wp_config : $key = $value"
        fi
    done
}