#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

install_mariadb() {
    MY_CNF="/etc/mysql/my.cnf"
    SLOW_LOG="/var/lib/mysql/mysql-slow.log"
    BUFFER_SIZE="1G"
    CACHE_SIZE="64G"
    TIMEOUT="60"

    echo "Configuration de MariaDB en cours ..."

    #Installation de MariaDB si ce n'est pas déjà fait
    if ! command -v mariadb &>/dev/null; then # Vérifie si mariadb echoue et envoie la sortie vers une sorte de poubelle virtuelle
        echo "MariaDB n'est pas encore installé. Installation en cours..."

        apt update
        apt install -y software-properties-common
        apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
        add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.6/ubuntu focal main'
        apt update
        apt install -y mariadb-server mariadb-client

        echo "Installation de MariaDB terminée avec succès. Version: $(mariadb --version)"
    else
        echo "MariaDB est déjà installé. Version : $(mariadb --version)"
    fi
}

configure_mariadb() {

    # Configuration du fichier my.cnf
    if [ -f "$MY_CNF" ]; then
        cp "$MY_CNF" "${MY_CNF}.bak"
        echo "Sauvegarde de $MY_CNF effectuée dans ${MY_CNF}.bak."
    else
        echo "Fichier $MY_CNF introuvable. Création d'un nouveau fichier."
        touch "$MY_CNF"
    fi

    # Vérification de chaque paramètre avant de l'ajouter
    add_param() {
        local param="$1"
        local value="$2"
        if ! grep -q "^[[:space:]]*$param" "$MY_CNF"; then #si un ou plusieurs espace avant
            echo "$param = $value" >> "$MY_CNF"
            echo "Ajouté : $param = $value"
        else
            echo "Paramètre $param déjà configuré."
        fi
    }

    echo "Vérification et ajout des paramètres dans $MY_CNF ..."

    # Taille du pool de tampons InnoDB
    add_param "innodb_buffer_pool_size" "$BUFFER_SIZE"

    # Désactiver la recherche DNS
    add_param "skip-name-resolve" ""

    # Taille du cache de requête
    add_param "query_cache_size" "$CACHE_SIZE"

    # Timeout des connexions inactives
    add_param "wait_timeout" "$TIMEOUT"

    # Activer les journaux de requêtes lentes
    add_param "slow-query-log" "1"
    add_param "slow-query-log-file" "$SLOW_LOG"
    add_param "long_query_time" "1"

    # Créer le fichier de log des requêtes lentes si nécessaire
    if [ ! -f "$SLOW_LOG" ]; then
        touch "$SLOW_LOG"
        chown mysql:mysql "$SLOW_LOG"
        echo "Fichier de log des requêtes lentes créé : $SLOW_LOG"
    fi

    # Redémarrer le service MariaDB
    echo "Redémarrage du service MariaDB..."
    systemctl restart mariadb

    echo "Configuration terminée avec succès !"

    # Conseils supplémentaires
    echo "N'oubliez pas de sécuriser MariaDB avec : sudo mysql_secure_installation"

}

create_database_user() {
    echo "Vérification de l'existence de l'utilisateur '$DB_USER' ..."

    USER_EXISTS=$(mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -h "$DB_HOST" -se \
        "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER');")

    if [ "$USR_EXISTS" == 1 ]; then
        echo "L'utilisateur '$DB_USER' existe déjà."
    else
        echo "Création de l'utilisateur '$DB_USER' et de la base '$DB_NAME' ..."
        mysql -u "$DB_USER_ROOT" -p"$DB_ROOT_PASSWORD" -h "$DB_HOST" -e \
            "CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';
            CREATE DATABASE IF NOT EXISTS $DB_NAME;
            GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST';
            FLUSH PRIVILEGES;"
         echo "Utilisateur '$DB_USER' créé avec succès et associé à la base '$DB_NAME'.*"
    fi
}