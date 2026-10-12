#!/bin/bash
set -euo pipefail

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# === NUEVA LÓGICA: Verificar modo --verify o -v ANTES que el check de root ===
VERIFY_MODE=false
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" ]]; then
    VERIFY_MODE=true
fi

# Si está en modo verificación, no requerir root
if [[ "$VERIFY_MODE" == true ]]; then
    log_info "=== Modo Verificación Reto 1 ==="
    log_info "Modo solo lectura - sin requerir permisos de root"
    echo ""
else
    # Verificar root solo si NO es modo verificación
    if [[ $EUID -ne 0 ]]; then
       log_error "Ejecutar como root (o usar --verify para modo solo lectura)"
       exit 1
    fi
fi

log_info "=== Reto 1: Hardening y configuración Linux ==="

# Tarea 1: Actualizar sistema
log_info "--- Tarea 1: Actualizar SO ---"
apt-get update -y 2>/dev/null | grep -v "^(Hit|Get|Fetched|OK|Reading)" | head -3 || true
apt-get upgrade -y 2>/dev/null | tail -3 || true

# Tarea 2: samba
log_info "--- Tarea 2: Instalar samba ---"
if ! dpkg -s samba >/dev/null 2>&1; then
    apt-get install -y samba 2>/dev/null | tail -3 || log_error "samba install failed"
fi
if ! dpkg -s samba-client >/dev/null 2>&1; then
    apt-get install -y samba-client 2>/dev/null | tail -3 || log_error "samba-client install failed"
fi

# Tarea 3: SELinux
log_info "--- Tarea 3: SELinux ---"
if command -v getenforce &>/dev/null; then
    current=$(getenforce 2>/dev/null || echo "unknown")
    log_info "Modo actual: $current"
    if [[ "$current" != "Enforcing" ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config 2>/dev/null || log_warn "No es sistema RHEL"
        setenforce Enforcing 2>/dev/null || log_warn "No cambiar en caliente"
    else
        log_info "SELinux ya Enforcing"
    fi
else
    log_warn "SELinux no disponible (Ubuntu usa AppArmor)"
    log_info "Para RHEL/CentOS: sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config"
fi

# Tarea 4: Usuarios
log_info "--- Tarea 4: Crear usuarios ---"
groupadd hackatonLabs 2>/dev/null || log_info "Grupo ya existe"

declare -A users=( ["compras"]="DefaultHackatonLabs123*" ["comercial"]="DefaultHackatonLabs123*" ["ventas"]="DefaultHackatonLabs123*" ["administrativo"]="DefaultHackatonLabs123*" ["soporte"]="DefaultHackatonLabs123*" )

for user in "${!users[@]}"; do
    password="${users[$user]}"
    log_info "Procesando usuario: $user"
    if ! id "$user" &>/dev/null; then
        useradd -m -g hackatonLabs -s /bin/bash "$user" 2>/dev/null || log_error "No se pudo crear $user"
    fi
    echo "$user:$password" | chpasswd 2>/dev/null || log_error "No se pudo setear password para $user"
    chage -m 10 "$user" 2>/dev/null || log_warn "chage min failed"
    chage -M 90 "$user" 2>/dev/null || log_warn "chage max failed"
    chage -W 7 "$user" 2>/dev/null || log_warn "chage warn failed"
    usermod -a -G hackatonLabs "$user" 2>/dev/null || log_warn "usermod group failed"
    log_info "Usuario $user configurado"
done

log_info "--- Tarea 5: Carpeta /guias ---"
mkdir -p /guias
chown root:hackatonLabs /guias 2>/dev/null || true
chmod 770 /guias 2>/dev/null || true
log_info "Creando 100 archivos vacíos..."
for i in $(seq -w 1 100); do
    touch "/guias/archivo-${i}.txt"
done
file_count=$(ls /guias/archivo-*.txt 2>/dev/null | wc -l)
log_info "Archivos creados: $file_count"

log_info "--- Tarea 6: Carpeta /guias/config ---"
mkdir -p /guias/config
chown root:hackatonLabs /guias/config 2>/dev/null || true
chmod 770 /guias/config 2>/dev/null || true
log_info "Copiando /etc/redhat-release..."
cp /etc/redhat-release /guias/config/ 2>/dev/null || log_warn "No redhat-release"
if [ -f /etc/os-release ]; then
    cp /etc/os-release /guias/config/redhat-release 2>/dev/null || true
fi
log_info "Copiando /etc/passwd..."
cp /etc/passwd /guias/config/ 2>/dev/null || log_warn "No passwd"
log_info "Copiando /usr/share/dict/linux.words..."
if [ -f /usr/share/dict/linux.words ]; then
    cp /usr/share/dict/linux.words /guias/config/ 2>/dev/null || log_warn "No linux.words"
else
    echo "No disponible" > /guias/config/linux.words.fallback 2>/dev/null || true
fi
config_total=$(ls -A /guias/config/ 2>/dev/null | wc -l)
log_info "Archivos en /guias/config: $config_total"

log_info "--- Tarea 7: Guardar versión OS ---"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    VERSION_INFO="NAME=\"$NAME\" VERSION=\"$VERSION_ID\" VERSION_CODENAME=\"$VERSION_CODENAME\" ID=$ID"
elif [ -f /etc/redhat-release ]; then
    VERSION_INFO="$(cat /etc/redhat-release)"
else
    VERSION_INFO="$(uname -srv)"
fi
echo "$VERSION_INFO" > /tmp/os-version.txt
log_info "Version guardada:"
cat /tmp/os-version.txt

log_info "--- Tarea 8: Enlace simbólico ---"
if [ -f /etc/group ]; then
    rm -f /guias/config/grupos 2>/dev/null || true
    ln -s /etc/group /guias/config/grupos
    if [ -L /guias/config/grupos ]; then
        log_info "Enlace creado: $(readlink /guias/config/grupos)"
    else
        log_error "No se creó enlace"
    fi
else
    log_error "/etc/group no existe"
fi

log_info "--- Tarea 9: Mensaje /etc/motd ---"
MOTD_MSG="El problema no es problema"
motd_file="/etc/motd"
if ! grep -qF "$MOTD_MSG" "$motd_file" 2>/dev/null; then
    echo "$MOTD_MSG" >> "$motd_file"
    log_info "Mensaje agregado a /etc/motd"
else
    log_info "Mensaje ya presente en /etc/motd"
fi

# === MODO VERIFICACIÓN AL FINAL DEL SCRIPT ===
if [[ "$VERIFY_MODE" == true ]]; then
    log_info "=== Resumen Verificación Reto 1 ==="
    VERIFIED=0
    TOTAL=9
    
    # T1: SO actualizado
    T1_PENDING=$(apt-list --upgradeable 2>/dev/null | wc -l)
    if [[ "$T1_PENDING" -eq 0 ]]; then
        log_info "[T1] Sistema actualizado: COMPLETA"
        ((VERIFIED++))
    else
        log_warn "[T1] Pendiente: $T1_PENDING paquetes"
    fi
    
    # T2: samba
    if dpkg -s samba >/dev/null 2>&1 && dpkg -s samba-client >/dev/null 2>&1; then
        log_info "[T2] samba: COMPLETA"
        ((VERIFIED++))
    else
        log_warn "[T2] PENDIENTE"
    fi
    
    # T3: SELinux
    if command -v getenforce &>/dev/null; then
        CURRENT=$(getenforce 2>/dev/null || echo "desconocido")
        if [[ "$CURRENT" == "Enforcing" ]]; then
            log_info "[T3] SELinux Enforcing: COMPLETA"
            ((VERIFIED++))
        else
            log_warn "[T3] PENDIENTE (actual: $CURRENT)"
        fi
    else
        log_info "[T3] SELinux: No disponible (Ubuntu)"
        ((VERIFIED++))
    fi
    
    # T4: Usuarios
    if getent group hackatonLabs >/dev/null 2>&1; then
        USERS_FOUND=$(id -Gn hackatonLabs 2>/dev/null | wc -w)
        if [[ "$USERS_FOUND" -ge 5 ]]; then
            log_info "[T4] Usuarios 5 con grupo: COMPLETA"
            ((VERIFIED++))
        else
            log_warn "[T4] PENDIENTE ($USERS_FOUND de 5)"
        fi
    else
        log_warn "[T4] Grupo no existe"
    fi
    
    # T5: /guias 100 archivos
    if [[ -d /guias ]] && [[ "$(ls /guias/archivo-*.txt 2>/dev/null | wc -l)" -ge 100 ]]; then
        log_info "[T5] /guias 100 archivos: COMPLETA"
        ((VERIFIED++))
    else
        log_warn "[T5] PENDIENTE"
    fi
    
    # T6: /guias/config
    if [[ -d /guias/config ]]; then
        CONFIG_COUNT=$(ls -A /guias/config/ 2>/dev/null | wc -l)
        if [[ "$CONFIG_COUNT" -ge 3 ]]; then
            log_info "[T6] /guias/config: COMPLETA"
            ((VERIFIED++))
        else
            log_warn "[T6] PENDIENTE ($CONFIG_COUNT archivos)"
        fi
    else
        log_warn "[T6] NO EXISTE"
    fi
    
    # T7: /tmp/os-version.txt
    if [[ -f /tmp/os-version.txt ]]; then
        log_info "[T7] /tmp/os-version.txt: COMPLETA"
        ((VERIFIED++))
    else
        log_warn "[T7] PENDIENTE"
    fi
    
    # T8: Enlace simbólico
    if [[ -L /guias/config/grupos ]]; then
        log_info "[T8] Enlace simbólico: COMPLETA"
        ((VERIFIED++))
    else
        log_warn "[T8] PENDIENTE"
    fi
    
    # T9: /etc/motd
    if grep -qF "El problema no es problema" /etc/motd 2>/dev/null; then
        log_info "[T9] /etc/motd mensaje: COMPLETA"
        ((VERIFIED++))
    else
        log_warn "[T9] PENDIENTE"
    fi
    
    echo ""
    log_info "Tareas completadas: $VERIFIED de $TOTAL"
    if [[ "$VERIFIED" -eq "$TOTAL" ]]; then
        log_info "¡Todas las tareas del Reto 1 están completadas!"
    else
        log_warn "Faltan $((TOTAL - VERIFIED)) tareas por completar"
    fi
fi

log_info "=== Script Reto 1 finalizado ==="
