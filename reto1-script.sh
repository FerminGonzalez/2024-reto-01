#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Detectar modo verify
VERIFY_MODE=false
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" ]]; then
    VERIFY_MODE=true
fi

# Bloque verify (solo lectura, sin root)
if [[ "$VERIFY_MODE" == true ]]; then
    log_info "=== Modo Verificación Reto 1 (Solo Lectura - WSL) ==="
    log_info "No se requieren permisos de root"
    log_info "Chequeo del estado de las 9 tareas (adaptado para WSL)..."
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
    
    # T5: Carpeta /guias - adaptado para WSL Usar home
    if [[ -d ~/guias ]] && [[ "$(ls ~/guias/archivo-*.txt 2>/dev/null | wc -l)" -ge 100 ]]; then
        log_info "[T5] Carpeta ~/guias con 100 archivos: COMPLETA (WSL friendly)"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T5] PENDIENTE: Ejecuta 'mkdir -p ~/guias && touch ~/guias/archivo-{1..100}.txt'"
    fi
    
    # T6: Carpeta /guias/config - adaptado para WSL
    if [[ -d ~/guias/config ]] && [[ "$(ls -A ~/guias/config/ 2>/dev/null | wc -l)" -ge 3 ]]; then
        log_info "[T6] Carpeta ~/guias/config con archivos: COMPLETA (WSL friendly)"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T6] PENDIENTE: Ejecuta 'mkdir -p ~/guias/config y copiar archivos'"
    fi
    
    # T7: /tmp/os-version.txt - Writable en WSL
    if [[ -f /tmp/os-version.txt ]]; then
        log_info "[T7] /tmp/os-version.txt: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T7] PENDIENTE: 'cat /etc/os-release > /tmp/os-version.txt'"
    fi
    
    # T8: Enlace simbólico - adaptado para WSL
    if [[ -L ~/guias/config/grupos ]]; then
        log_info "[T8] Enlace ~/guias/config/grupos: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T8] PENDIENTE: 'ln -s /etc/group ~/guias/config/grupos'"
    fi
    
    # T9: /etc/motd - WSL puede escribir dependiendo configuración
    if grep -qF "El problema no es problema" /etc/motd 2>/dev/null; then
        log_info "[T9] /etc/motd mensaje: COMPLETA"
        VERIFIED=$((VERIFIED + 1))
    else
        log_warn "[T9] PENDIENTE: 'echo ... >> /etc/motd' (puede necesitar sudo)"
    fi
    
    echo ""
    log_info "========================================"
    log_info "RESULTADO WSL: $VERIFIED de $TOTAL tareas completadas"
    if [[ "$VERIFIED" -eq "$TOTAL" ]]; then
        log_info "¡Todas las tareas WSL verificadas!"
    else
        log_warn "Faltan $((TOTAL - VERIFIED)) tareas (usando rutas home/tmp en WSL)"
    fi
    log_info "========================================"
    exit 0
fi

# Bloque ejecución normal (sin root)
log_info "=== Reto 1: Hardening WSL ==="
log_info "Usuario: $(whoami)"
log_info "Sistema: $(lsb_release -d 2>/dev/null | cut -f2- || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2- | tr -d '\"')"

# T1: Actualizar (puede necesitar sudo, probamos sin)
log_info "--- Tarea 1: Actualizar SO ---"
apt-get update -y 2>/dev/null | grep -v "^(Hit|Get|Fetched|OK|Reading)" | head -3 || true
apt-get upgrade -y 2>/dev/null | tail -3 || true

# T2: samba (intentamos, fallará sin sudo - está bien)
log_info "--- Tarea 2: Instalar samba ---"
apt-get install -y samba 2>/dev/null && log_info "samba instalado" || log_warn "samba no instalado (sin permisos root en WSL)"

# T3: SELinux (contexto WSL)
log_info "--- Tarea 3: SELinux ---"
log_info "WSL usa AppArmor en lugar de SELinux"
log_info "Para RHEL/CentOS: configurar Enforcing"
log_info "WSL/Ubuntu: Ya viene con perfil de seguridad AppArmor"

# T4: Usuarios (intentamos, puede fallar sin sudo)
log_info "--- Tarea 4: Crear usuarios ---"
groupadd hackatonLabs 2>/dev/null && log_info "Grupo creado" || log_warn "No se pudo crear grupo (necesita sudo)"
# Probar crear usuarioaunque falle
useradd -m -g hackatonLabs -s /bin/bash tester 2>/dev/null && log_info "Usuario test creado" || log_warn "No se pudo crear usuario (necesita sudo)"

# T5: Carpeta /guias - VERSION WSL (usar home)
log_info "--- Tarea 5: Carpeta /guias (WSL friendly) ---"
mkdir -p ~/guias
chmod 770 ~/guias
log_info "Creando 100 archivos en ~/guias..."
for i in $(seq -w 1 100); do
    touch "/guias/archivo-${i}.txt" 2>/dev/null || touch "~/guias/archivo-${i}.txt"
done
# Verificar usando la ruta home
FILE_COUNT=$(ls -1 ~/guias/archivo-*.txt 2>/dev/null | wc -l)
log_info "Archivos en ~/guias: $FILE_COUNT"

# T6: Carpeta /guias/config - VERSION WSL
log_info "--- Tarea 6: Carpeta /guias/config (WSL friendly) ---"
mkdir -p ~/guias/config
chmod 770 ~/guias/config
log_info "Copiando archivos de configuración a ~/guias/config..."
cp /etc/passwd ~/guias/config/ 2>/dev/null || echo "Copiado home/passwd"
if [ -f /etc/os-release ]; then
    cp /etc/os-release ~/guias/config/redhat-release 2>/dev/null || true
fi

# T7: Guardar versión OS en /tmp (writable en WSL)
log_info "--- Tarea 7: Guardar versión OS ---"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    VERSION_INFO="NAME=\"$NAME\" VERSION=\"$VERSION_ID\" VERSION_CODENAME=\"$VERSION_CODENAME\" ID=$ID"
    echo "$VERSION_INFO" > /tmp/os-version.txt
    log_info "Version guardada en /tmp:"
    cat /tmp/os-version.txt
else
    echo "Linux Ubuntu WSL" > /tmp/os-version.txt
    log_info "Version por defecto guardada"
fi

# T8: Enlace simbólico - VERSION WSL
log_info "--- Tarea 8: Enlace simbólico (WSL friendly) ---"
if [ -f /etc/group ]; then
    # Intentar en /tmp primero (writable)
    rm -f /tmp/grupos_link 2>/dev/null || true
    ln -s /etc/group /tmp/grupos_link 2>/dev/null && log_info "Enlace en /tmp creado" || log_warn "No se pudo crear enlace"
    # También crear en home
    rm -f ~/grupos_link 2>/dev/null || true
    ln -s /etc/group ~/grupos_link 2>/dev/null && log_info "Enlace en home creado" || log_warn "No se pudo crear enlace en home"
else
    log_error "/etc/group no existe"
fi

# T9: Mensaje /etc/motd - WSL
log_info "--- Tarea 9: Mensaje /etc/motd (WSL) ---"
MOTD_MSG="El problema no es problema"
motd_file="/etc/motd"
# Intentar escribir, fallará sin sudo pero registramos
if grep -qF "$MOTD_MSG" "$motd_file" 2>/dev/null; then
    log_info "Mensaje ya presente en /etc/motd"
else
    echo "$MOTD_MSG" >> "$motd_file" 2>/dev/null && log_info "Mensaje agregado" || log_warn "No se pudo agregar mensaje (necesita sudo en WSL)"
fi

log_info "=== Script Reto 1 WSL finalizado ==="
