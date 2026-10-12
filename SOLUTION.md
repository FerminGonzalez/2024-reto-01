# Reto 01 — Solución (Un día en HackathonLabs Networks)

Este reto **no** se despliega en Microsoft Azure, por lo que la solución se documenta aquí y se
entrega como un **playbook de Ansible** listo para ejecutar en el ambiente del hackathon.

Archivos de la solución:

- `Inventory/servers` — inventario a completar con las IP **privadas** y credenciales del ambiente.
- `Inventory/site.yml` — playbook que resuelve las 9 tareas de configuración.

## 1. Preparación del inventario

Editar `Inventory/servers` reemplazando `<IP>`, `usuario_admin` y `your_password` con los datos
entregados en el documento del equipo (`TEAM_CODE` + `TEAM_NUMBER`). Recordar usar la **IP privada**.

```ini
web1 ansible_host=10.15.<NUM>.130 ansible_user=usuario_admin ansible_ssh_pass=...
web2 ansible_host=10.15.<NUM>.131 ansible_user=usuario_admin ansible_ssh_pass=...
db   ansible_host=10.15.<NUM>.132 ansible_user=usuario_admin ansible_ssh_pass=...
```

## 2. Ejecución del playbook

Solo desde el **bastión** (que tiene Ansible instalado):

```bash
ansible-playbook -i servers site.yml
```

## 3. Mapeo tarea -> recurso del playbook

| Tarea del reto | Recurso en `site.yml` |
|---|---|
| 1. SO completamente actualizado | `dnf: name="*" state=latest` |
| 2. Última versión de samba / samba-client | `dnf: name=[samba, samba-client] state=latest` |
| 3. SELinux activo permanente | `ansible.posix.selinux: state=enforcing` |
| 4. Grupo `hackatonLabs` + 5 usuarios, expiración 90/10/7 | `group` + `user` con `password_expire_max/min/warn` |
| 5. `/guias` del grupo con rwx + 100 archivos vacíos | `file: /guias mode=0770` + `copy content=""` en loop 1..100 |
| 6. `/guias/config` + copiar `redhat-release`, `passwd`, `linux.words` | `file` + `copy remote_src=true` |
| 7. Versión exacta del SO en `/tmp/os-version.txt` | `shell: cat /etc/redhat-release > /tmp/os-version.txt` |
| 8. Symlink `/guias/config/grupos` -> `/etc/group` | `file: state=link` |
| 9. MOTD "El problema no es problema" | `copy content=... dest=/etc/motd` |

## 4. Configuración manual del Fortigate (no automatizable)

1. **Licenciar** el Fortigate en modo *Permanent trial mode* con una cuenta nueva en
   <https://support.fortinet.com/> (borrar cualquier licencia/cuenta previa: solo se permite una).
2. Crear los **Addresses** (objetos), nunca usar IPs/segmentos sueltos en las políticas:
   `ADDR_address_space` = supernet, `ADDR_inside_004`, `ADDR_servers_005`, `ADDR_web`,
   `ADDR_vip_public`, `ADDR_all` = `0.0.0.0/0`.
3. **Rutas estáticas**: destino = address space vía gateway `10.15.<NUM>.65` (1ª IP de la subred 003).
4. Crear tres **políticas**:
   1. *Internet (North-South)*: `inside -> outside`, origen `address_space`, destino `0.0.0.0/0`,
      servicios `HTTP HTTPS DNS`.
   2. *East-West*: `inside -> inside`, origen subred `004` (DMZ), destino subred `005` (servers).
   3. *Publicación FE (Inbound)*: `outside -> inside`, origen `0.0.0.0/0`, destino el **VIP**,
      servicios `HTTP HTTPS`.
5. **Publicación del FrontEnd**:
   1. IP secundaria en la interfaz `outside` = la IP siguiente a la actual (7ª IP de la subred 002).
   2. **Virtual IP (VIP)**: external address = la IP secundaria; mapped address = IP del servidor web.
   3. Política inbound (paso 4.3) usando ese VIP.
