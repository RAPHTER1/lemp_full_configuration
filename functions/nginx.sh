#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

install_nginx() {
    
    # Variables
    NGINX_CONF="/etc/nginx/nginx.conf"

    #Installation de nginx
    echo "Installation de Nginx"

    #Vérifier si nginx  déjà installer
    if ! command -v nginx &> /dev/null ; then
        apt update

        echo "Lancement de l'installation de nginx"
        apt install nginx -y
        echo "Installation de Nginx terminé. $(nginx --version)"
    else
        echo "Nginx est déjà installée. $(nginx --version)"
    fi

    #Démarrer le service à chaque redémarage du système
    systemctl enable nginx

    #Démarrage du service
    systemctl start nginx

    #Vérifie l'état du service nginx
    systemctl status nginx

    #Vérifié si le fichier nginx.conf existe
    if [ -f "$NGINX_CONF" ]; then
        mv "$NGINX_CONF" "${NGINX_CONF}.backup"
        touch "$NGINX_CONF"
        echo "Sauvegarde du fichier $NGINX_CONF."
    else
        touch "$NGINX_CONF"
        echo "Création du fichier $NGINX_CONF."
    fi

    cat > $NGINX_CONF <<EOL

    events {
    }
    http {
        server {
            listen 80;
            server_name serveurnginx.cours-datascientest.cloudns.ph;
            return 200 "Welcome to Datascientest, we are on the NGINX course!\n";
        }
    }

EOL

    #Vérification du fichier conf et redemarrage d'Nginx
    if nginx -t &> /dev/null ; then
        echo "Le fichier de configuration ne contient pas d'erreur."
        echo "Redemarrage de Nginx en cours ..."
        systemctl restart nginx
        nginx -s reload
    else
        echo "Le fichier $NGINX_CONF comporte une erreur. Merci de corriger le script."
        nginx -t
    fi

}