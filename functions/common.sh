#Vérifier que le script est sourcé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Ce script ne peut pas être exécuté directement. Utilisez main.sh."
    exit 1
fi

check_root() {
    if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo ou en tant que root."
    exit 1
fi
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}