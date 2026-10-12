# Makefile para Reto 1: Hardening y configuración Linux
# Autor: Fermin Gonzalez (ferming1541@gmail.com)
# Repositorio: FerminGonzalez/2024-reto-01

.PHONY: all verify install help

all: ## Ejecutar todas las tareas de hardening (requiere root)
	@echo "Ejecutando Reto 1: Hardening Linux..."
	@sudo bash reto1-script.sh

verify: ## Verificar estado de las 9 tareas (sin root)
	@echo "Verificando estado Reto 1..."
	@bash reto1-script.sh --verify

help: ## Mostrar ayuda
	@echo "Comandos disponibles:"
	@echo "  make all     - Ejecutar todas las tareas (necesita sudo)"
	@echo "  make verify  - Verificar estado sin root"
	@echo "  make help    - Mostrar esta ayuda"

.DEFAULT_GOAL := help
