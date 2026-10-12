# 2024-reto-01 - Fortigate Firewall Challenge

## Propósito
Desafío de hackathon 2024: Configuración de firewall Fortigate para segmentación de redes y acceso seguro a servidores MTWA FlightDB.

## Contexto
- Reto #1 de HackathonLabs Networks
- Servidor web: acceso internet solo http/https/dns
- Microsegmentación East-West: FE → BE solo
- Servidor web público: IP pública distinta, solo http/https
- Fortigate requiere licencia (trial mode o permanente)

## Comandos habituales
```bash
# Ver estado actual
cat readme.md

# Ver estructura
ls -la
ls imgs/
ls Inventory/
```

## Rutas importantes
- `README.md` - Descripción general
- `SOLUTION.md` - Solución detallada
- `reto1.md` - Enunciado del reto
- `Inventory/` - Inventario de recursos
- `imgs/` - Diagramas e imágenes

## Formato de commits (Convencionales)
```
git commit -m "tipo: descripción breve"

tipos sugeridos:
- docs: documentación
- fix: corrección de configuración
- feat: nueva regla/feature
- config: cambio de configuración
```

## Estado actual
- Repositorio clonado localmente
- Remote origin configurado a GitHub
- Sin commits pendientes locales
