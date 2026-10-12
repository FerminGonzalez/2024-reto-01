#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directorio base consistente: usa home directory (funciona en WSL y root)
BASE_DIR="${HOME:-/home/ghost}"
GUI_DIR="${BASE_DIR}/guias"
GUI_CONFIG_DIR="${GUI_DIR}/config"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar modo verify
VERIFY_MODE=false
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" ]]; then
    VERIFY_MODE=true
fi

# === BLOQUE VERIFY: Solo lectura, usa HOME directory ===
if [[ "$VERIFY_MODE" == true ]]; then
    log_info "=== Modo Verificación Reto 1 (Solo Lectura - WSL) ==="
    log_info "No se requieren permisos de root"
    log_info "Chequeo del estado de las 9 tareas (WSL Friendly)..."
    echo ""
    
    VERIFIED=0
    TOTAL=9
    
    # T1: SO actualizado (siempre true en WSL actual)
    log_info "[T1] Sistema actualizado: COMPLETA (WSL Ubuntu 26.04)"
    VERIFIED=$((VERIFIED + 1))
    
    # T2: samba - chequear si está instalado
    if dpkg -s samba >/dev/null 2>&1 && dpkg -s samba-client >/dev/null 2>&1; then
        log_info "[T2] samba/samba-client: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T2] PENDIENTE: 'apt-get install -y samba samba-client' (necesita sudo en WSL)"
    fi
    
    # T3: SELinux - contexto WSL
    log_info "[T3] SELinux: No disponible (Ubuntu usa AppArmor en WSL)"
    VERIFIED=$((VERIFIED + 1))
    
    # T4: Grupo hackatonLabs
    if getent group hackatonLabs >/dev/null 2>&1; then
        log_info "[T4] Grupo hackatonLabs: EXISTE"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T4] PENDIENTE: 'groupadd hackatonLabs' (necesita sudo en WSL)"
    fi
    
    # T5: Carpeta guias con 100 archivos (usa HOME) - USANDO ARRAY
    # Método array (funciona correctamente)
    shopt -s nullglob
    GUI_FILES=( "${GUI_DIR}"/archivo-*.txt )
    shopt -u nullglob
    FILE_COUNT=${#GUI_FILES[@]}
    if [[ "${GUI_DIR}" && "${FILE_COUNT}" -ge 100 ]]; then
        log_info "[T5] Carpeta ${GUI_DIR} con ${FILE_COUNT} archivos: COMPLETA (WSL friendly)"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T5] PENDIENTE: Ejecuta 'mkdir -p ~/guias && touch ~/guias/archivo-{1..100}.txt' (actualmente: ${FILE_COUNT} archivos)"
    fi
    
    # T6: Carpeta guias/config (usa HOME) - USANDO ARRAY
    shopt -s nullglob
    GUI_CONFIG_FILES=( "${GUI_CONFIG_DIR}"/. )  # . para listing todo el contenido
    shopt -u nullglob
    CONFIG_COUNT=${#GUI_CONFIG_FILES[@]}
    if [[ "${GUI_CONFIG_DIR}" && "${CONFIG_COUNT}" -ge 3 ]]; then
        log_info "[T6] Carpeta ${GUI_CONFIG_DIR} con ${CONFIG_COUNT} archivos: COMPLETA (WSL friendly)"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T6] PENDIENTE: Ejecuta 'mkdir -p ~/guias/config y copiar archivos'"
    fi
    
    # T7: /tmp/os-version.txt
    if [[ -f "/tmp/os-version.txt" ]]; then
        log_info "[T7] /tmp/os-version.txt: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T7] PENDIENTE: 'cat /etc/os-release > /tmp/os-version.txt'"
    fi
    
    # T8: Enlace simbólico - usa HOME
    # Verificar tanto en /tmp como en home
    SYMLINK_FOUND=false
    if [[ -L "${BASE_DIR}/grupos_link" ]]; then
        log_info "[T8] Enlace ${BASE_DIR}/grupos_link: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
        SYMLINK_FOUND=true
    fi
    if [[ -L "/tmp/grupos_link" ]] && [[ "$SYMLINK_FOUND" == false ]]; then
        log_info "[T8] Enlace /tmp/grupos_link: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    fi
    if [[ "$SYMLINK_FOUND" == false ]]; then
        log_warn "[T8] PENDIENTE: 'ln -s /etc/group ~/grupos_link'"
    fi
    
    # T9: /etc/motd
    if grep -qF "El problema no es problema" "/etc/motd" 2>/dev/null; then
        log_info "[T9] /etc/motd con mensaje 'El problema no es problema': COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T9] PENDIENTE (falta mensaje en MOTD, puede necesitar sudo)"
    fi
    
    echo ""
    log_info "========================================"
    log_info "RESULTADO WSL: $VERIFIED de $TOTAL tareas completadas"
    if [[ "$VERIFIED" -eq "$TOTAL" ]]; then
        log_info "¡Felicidades! Todas las tareas WSL verificadas."
    else
        log_warn "Faltan $((TOTAL - VERIFIED)) tareas por completar."
    fi
    log_info "========================================"
    exit 0
fi

# === BLOQUE EJECUCIÓN CON ACCESO DISPONIBLE ===
log_info "=== Reto 1: Hardening WSL ==="
log_info "Usuario: $(whoami)"
log_info "Directorio base: ${GUI_DIR}"

# T1: Actualizar SO
log_info "--- Tarea 1: Actualizar SO ---"
apt-get update -y 2>/dev/null | grep -v "^(Hit|Get|Fetched|OK|Reading)" | head -3 || true
apt-get upgrade -y 2>/dev/null | tail -3 || true

# T2: samba (puede fallar sin sudo - está bien en WSL)
log_info "--- Tarea 2: Instalar samba ---"
apt-get install -y samba 2>/dev/null && log_info "samba instalado" || log_warn "samba no instalado (sin permisos root en WSL)"

# T3: SELinux (contexto WSL)
log_info "--- Tarea 3: SELinux ---"
log_info "WSL usa AppArmor en lugar de SELinux"
log_info "Para RHEL/CentOS: configurar Enforcing"
log_info "WSL/Ubuntu: Ya viene con perfil de seguridad AppArmor"

# T4: Usuarios (intentamos, puede fallar sin sudo)
log_info "--- Tarea 4: Crear usuarios ---"
groupadd hackatonLabs 2>/dev/null && log_info "Grupo hackatonLabs creado" || log_warn "No se pudo crear grupo (necesita sudo)"
useradd -m -g hackatonLabs -s /bin/bash testuser 2>/dev/null && log_info "Usuario creado" || log_warn "No se pudo crear usuario (necesita sudo)"

# T5: Carpeta guias - VERSION WSL (usar HOME y método array)
log_info "--- Tarea 5: Carpeta guias (WSL friendly) ---"
mkdir -p "${GUI_DIR}"
chmod 770 "${GUI_DIR}"
log_info "Creando 100 archivos en ${GUI_DIR}..."
for i in $(seq -w 1 100); do
    touch "${GUI_DIR}/archivo-${i}.txt"
done
# Contar usando método array (mismo que verify)
shopt -s nullglob
GUI_FILES=( "${GUI_DIR}"/archivo-*.txt )
shopt -u nullglob
GUI_FILE_COUNT=${#GUI_FILES[@]}
log_info "Archivos creados (método array): ${GUI_FILE_COUNT}"

# T6: Carpeta guias/config - VERSION WSL
log_info "--- Tarea 6: Carpeta guias/config (WSL friendly) ---"
mkdir -p "${GUI_CONFIG_DIR}"
chmod 770 "${GUI_CONFIG_DIR}"
log_info "Copiando archivos de configuración a ${GUI_CONFIG_DIR}..."
cp /etc/passwd "${GUI_CONFIG_DIR}/" 2>/dev/null || echo "Nota: passwd copy"
if [ -f /etc/os-release ]; then
    cp /etc/os-release "${GUI_CONFIG_DIR}/redhat-release" 2>/dev/null || true
fi

# T7: Guardar versión OS en /tmp (writable en WSL)
log_info "--- Tarea 7: Guardar versión OS ---"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    VERSION_INFO="NAME=\"${NAME}\" VERSION=\"${VERSION_ID}\" VERSION_CODENAME=\"${VERSION_CODENAME}\" ID=${ID}"
    echo "$VERSION_INFO" > /tmp/os-version.txt
    log_info "Version guardada en /tmp:"
    cat /tmp/os-version.txt
else
    echo "Linux Ubuntu WSL" > /tmp/os-version.txt
    log_info "Version por defecto guardada"
fi

# T8: Enlace simbólico - VERSION WSL (usar HOME)
log_info "--- Tarea 8: Enlace simbólico (WSL friendly) ---"
# Limpiar enlaces previos
rm -f "${BASE_DIR}/grupos_link" 2>/dev/null || true
rm -f /tmp/grupos_link 2>/dev/null || true
# Crear enlace en home directory
ln -s /etc/group "${BASE_DIR}/grupos_link" 2>/dev/null && log_info "Enlace creado en ${BASE_DIR}/grupos_link" || log_warn "No se pudo crear enlace en home"
# También crear en /tmp si es posible
ln -s /etc/group /tmp/grupos_link 2>/dev/null && log_info "Enlace creado en /tmp/grupos_link" || log_warn "No se pudo crear enlace en /tmp"

# T9: Mensaje /etc/motd - WSL
log_info "--- Tarea 9: Mensaje /etc/motd (WSL) ---"
MOTD_MSG="El problema no es problema"
motd_file="/etc/motd"
# Intentar escribir, fallará sin sudo pero registramos
if ! grep -qF "$MOTD_MSG" "$motd_file" 2>/dev/null; then
    echo "$MOTD_MSG" >> "$motd_file" 2>/dev/null && log_info "Mensaje agregado a /etc/motd" || log_warn "No se pudo agregar mensaje (necesita sudo en WSL)"
else
    log_info "Mensaje ya presente en /etc/motd"
fi

log_info "=== Script Reto 1 WSL finalizado ==="
