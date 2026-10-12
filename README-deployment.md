# Reto 1: Despliegue y Ejecución

## Descripción
Script de automatización para hardening de servidores Linux con 9 tareas críticas de seguridad y configuración.

## Repositorio
`FerminGonzalez/2024-reto-01` - https://github.com/FerminGonzalez/2024-reto-01

## Estructura del proyecto
```
2024-reto-01/
├── CLAUDE.md          # Brief del proyecto
├── DEVELOPMENT-LOG.md # Historial de desarrollo
├── Makefile           # Comandos de despliegue
├── reto1-script.sh    # Script principal (149 líneas)
├── Inventory/
├── imgs/
├── readme.md
├── reto1.md
└── SOLUTION.md
```

## Comandos de Despliegue

### 1. Clonar el repositorio
```bash
git clone https://github.com/FerminGonzalez/2024-reto-01.git
cd 2024-reto-01
```

### 2. Verificar estado actual (recomendado primero)
```bash
make verify
```
**Resultado:** Muestra qué de las 9 tareas ya completó su servidor y cuáles faltan.

### 3. Ejecutar hardening completo
```bash
sudo make all
```
**O equivalente:**
```bash
sudo bash reto1-script.sh
```
**Requisitos:** Ejecutar como usuario root (o con sudo).

**Tareas ejecutadas:**
1. Actualizar sistema operativo
2. Instalar samba y samba-client
3. Configurar SELinux Enforcing
4. Crear 5 usuarios con políticas de password (90 días expiración, mínimo 10 días entre cambios, aviso 7 días antes)
5. Carpeta `/guias` con 100 archivos vacíos
6. Carpeta `/guias/config` con archivos de configuración
7. Guardar versión OS en `/tmp/os-version.txt`
8. Enlace simbólico `/guias/config/grupos` -> `/etc/group`
9. Mensaje `"El problema no es problema"` en `/etc/motd`

## Modo Verificación (Sin root)

El modo verification es útil para:
- Servidores donde no tienes permisos de root
- Validar qué ya está configurado en un entorno existente
- Replicar el estado en múltiples servidores

```bash
make verify
```

**Salida ejemplo:**
```
RESULTADO: 2 de 9 tareas completadas
Faltan 7 tareas por completar.
```

## Personalización

### Modificar passwords
Editar el arreglo `users` en `reto1-script.sh`:
```bash
declare -A users=( ["compras"]="MiPasswordSegura123" ["comercial"]="OtraPassword456" )
```

### Cambiar intervalos de password
Modificar los valores en `chage`:
- `chage -m 10` → días mínimos entre cambios
- `chage -M 90` → días máximos de vigencia
- `chage -W 7` → días de aviso antes de expiración

### Cambiar el mensaje MOTD
Modificar la variable `MOTD_MSG` en el script:
```bash
MOTD_MSG="Mi mensaje personalizado"
```

## Verificación Post-Despliegue

Después de ejecutar `make all`, verificar el estado:

```bash
# Verificar users
cat /etc/passwd | grep hackatonLabs

# Verificar carpeta /guias
ls -la /guias/ | head -5
ls /guias/archivo-*.txt | wc -l

# Verificar MOTD
cat /etc/motd

# Verificar enlace simbólico
ls -la /guias/config/grupos
```

## historial de despliegue

Consultar `DEVELOPMENT-LOG.md` para el registro completo de cambios y decisiones tomadas durante el desarrollo.

## Licencia
Este proyecto forma parte del HackathonLabs Networks - Copa 2024 / Copa 2026.
