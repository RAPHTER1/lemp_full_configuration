#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

configure_php() {
    
}