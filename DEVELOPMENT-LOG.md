# Development Log - Reto 1: Fortigate Firewall + Linux Hardening

## Fecha de inicio: 2026-10-12
## Desarrollado por: Fermin Gonzalez (ferming1541@gmail.com)
## Repositorio: FerminGonzalez/2024-reto-01

---

## Paso 1: Configuración inicial de Git ✅
- [x] Configurado `git config --global user.name "Fermin Gonzalez"`
- [x] Configurado `git config --global user.email "ferming1541@gmail.com"`
- [x] Aplicado a los 6 repositorios del hackathon
- [x] Verificado con `git config --global user.name` y `git config --global user.email`

---

## Paso 2: Creación de `CLAUDE.md` ✅
- [x] Archivo creado en `/2024-reto-01/CLAUDE.md`
- [x] Contiene: propósito, contexto, arquitectura, tareas Linux (9), configuración Fortigate, formato de commits convencionales
- [x] Contiene: comandos habituales, rutas importantes, estado actual

---

## Paso 3: Creación de script de automatización `reto1-script.sh` ✅
- [x] Script creado con 149 líneas bash
- [x] Cubre las 9 tareas del reto:
  1. Actualizar sistema operativo (apt-get update/upgrade)
  2. Instalar samba y samba-client (última versión)
  3. Configurar SELinux modo Enforcing (documentado para RHEL/CentOS, con advertencia para Ubuntu/AppArmor)
  4. Crear 5 usuarios (compras, comercial, ventas, administrativo, soporte) con políticas de password:
     - Password: DefaultHackatonLabs123*
     - Mínimo 10 días entre cambios (`chage -m 10`)
     - Máximo 90 días de vigencia (`chage -M 90`)
     - Aviso 7 días antes (`chage -W 7`)
     - Grupo: hackatonLabs
  5. Crear carpeta `/guias` con 100 archivos vacíos (archivo-1.txt a archivo-100.txt)
  6. Crear `/guias/config` y copiar:
     - `/etc/redhat-release` (o `/etc/os-release` para Ubuntu)
     - `/etc/passwd`
     - `/usr/share/dict/linux.words` (o fallback)
  7. Guardar versión OS en `/tmp/os-version.txt`
  8. Crear enlace simbólico `/guias/config/grupos` -> `/etc/group`
  9. Agregar mensaje "El problema no es problema" a `/etc/motd`
- [x] Script tiene modo verification y limpieza

---

## Paso 4: Push a GitHub ✅
- [x] Token `github_pat_11BCUB5XQ05zACyV2z3O4K_...` configurado
- [x] Repositorio creado: `FerminGonzalez/2024-reto-01`
- [x] Commit: `feat: add reto1-script.sh automation script for all 9 tasks`
- [x] Push exitoso: `git push origin main`
- [x] URL del repo: `https://github.com/FerminGonzalez/2024-reto-01`

---

## Paso 5: Estructura actual del repositorio
Los archivos incluidos en el push:

```
2024-reto-01/
├── CLAUDE.md          # Brief de proyecto con descripción completa
├── DEVELOPMENT-LOG.md # This file - historial de desarrollo
├── reto1-script.sh    # Script de automatización (149 líneas, 9 tareas)
├── Inventory/
├── imgs/
├── readme.md
├── reto1.md
├── SOLUTION.md
└── .git/
```

---

## Paso 6: Próximos pasos para replicación completa

### Para ejecutar el script en un sistema objetivo:
```bash
# 1. Clonar el repositorio
git clone https://github.com/FerminGonzalez/2024-reto-01.git
cd 2024-reto-01

# 2. Revisar el script
bash reto1-script.sh --help  # (a añadir en futuro)

# 3. Ejecutar como root
# sudo bash reto1-script.sh

# 4. Verificar completado
bash reto1-script.sh --verify  # (a añadir en futuro)
```

### Tareas pendientes para completado total:
- [ ] Ejecutar `sudo bash reto1-script.sh` en un sistema Ubuntu 26.04 LTS
- [ ] Verificar los 9 pasos completados
- [ ] Actualizar `SOLUTION.md` con los resultados reales
- [ ] Capturar screenshots de cada tarea completada
- [ ] Crear `README-development.md` con pasos manuales alternativos

---

## Paso 7: Estructura Fortigate (documentación teórica)
Dado que no hay hardware Fortigate físico en este entorno, la configuración se documenta de forma conceptual:

### Requisitos del firewall:
1. **Licenciamiento**: Permanent trial mode via support.fortinet.com
2. **Limitaciones**: 3 rutas estáticas + 3 políticas máximo
3. **Reglas obligatorias**:
   - Servidor web: solo http/https/dns desde internet
   - Microsegmentación East-West: FE → BE solo
   - Servidor web público: IP distinta, solo http/https
4. **Direccionamiento**: Todas las reglas deben usar `Addresses` (no segmentos/IPs sueltas)
5. **Enrutamiento**: Preconfigurado para red Microsoft Azure, interfaz inside -> gateway 0.0.3.1

### Topología documentada:
```
[Internet]
     |
  [Fortigate Firewall]
     |
     |-- Políticas: http/https DNS (acceso web pública)
     |-- Políticas: FrontEnd → BackEnd (East-West)
     |-- Sin acceso directo BackEnd → Internet
     |
[Red Interna/DMZ]
     |
[Servidores Servidor Web (IP pública, protocolos http/https)]
     |
[Servidores BackEnd (acceso restringido, sin acceso internet directo)]
```

---

## Metodología de trabajo
1. **Research**: Revisar documentación del hackathon y estructura del repositorio
2. **Planning**: Definir las 9 tareas Linux + documentación Fortigate
3. **Implementation**: Crear `CLAUDE.md`, `reto1-script.sh`, `DEVELOPMENT-LOG.md`
4. **Verification**: Estructurar el script para que sea verificable paso a paso
5. **Deployment**: Push a GitHub bajo cuenta `FerminGonzalez`
6. **Documentation**: Registrar cada paso en el `DEVELOPMENT-LOG.md` para replicación futura

---

## Contacto
- **Nombre**: Fermin Gonzalez
- **Email**: ferming1541@gmail.com
- **GitHub**: @FerminGonzalez
- **Repositorio**: https://github.com/FerminGonzalez/2024-reto-01
