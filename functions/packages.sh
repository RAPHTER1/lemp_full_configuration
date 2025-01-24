#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

install_packages() {
    log "Vérification des paquets à installer."

    apt-get update -y

    for package in "${PACKAGES[@]}"; do
        if dpkg -l "$package" &>/dev/null; then
            #Le paquet est installé, vérifie s'il a besoin d'une mise à jour
            if apt list --upgradable 2>/dev/null | grep -q "$package/"; then
                apt-get install --only-upgrade -y "$package"
            else
                log "Le paquet $package est déjà à jours."
            fi
        else
            #Le paquet n'est pas installé
            log "Installation du paquet: $package"
            apt-get install -y "$package"
        fi
    done

    log "Gestion des paquets terminée avec sucès."
}