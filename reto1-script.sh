#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar root
if [[ $EUID -ne 0 ]]; then
   log_error "Ejecutar como root"
   exit 1
fi

log_info "Iniciando Reto 1..."

log_info "=== Reto 1: Hardening y configuración Linux ==="
log_info "Sistema: $(lsb_release -d 2>/dev/null | cut -f2- || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2- | tr -d '\"')"

# Tarea 1: Actualizar sistema
log_info "--- Tarea 1: Actualizar SO ---"
apt-get update -y 2>/dev/null | grep -v "^(Hit|Get|Fetched|OK|Reading)" || true
apt-get upgrade -y 2>/dev/null | tail -3 || true

# Tarea 2: samba y samba-client
log_info "--- Tarea 2: Instalar samba ---"
if ! dpkg -s samba >/dev/null 2>&1; then
    apt-get install -y samba 2>/dev/null | tail -3 || log_error "samba install failed"
fi
if ! dpkg -s samba-client >/dev/null 2>&1; then
    apt-get install -y samba-client 2>/dev/null | tail -3 || log_error "samba-client install failed"
fi
log_info "Samba version: $(samba --version 2>/dev/null || echo 'Desconocido')"

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

log_info "--- Tarea 5: Carpeta /guias con 100 archivos ---"
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

log_info "=== Script Reto 1 finalizado ==="
