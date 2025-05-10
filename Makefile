# Универсальный Makefile для Docker Compose
# Использование: make [команда]

# Переменные
COMPOSE := docker-compose
COMPOSE_FILE := docker-compose.yml
SERVICE_SQL := sqlserver_db
SERVICE_RABBIT := rabbitmq
SERVICE_REDIS := redis
PWSH := pwsh -NoProfile -ExecutionPolicy Bypass -File

# Основные команды
.PHONY: up up-build down logs clean build rebuild reset-db fill-dbs clean-dbs status help

## Запуск всех сервисов (в фоне)
up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d

## Запуск всех сервисов с пересборкой (в фоне)
up-build:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

## Остановка всех сервисов
down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

## Просмотр логов (всех сервисов или конкретного, например: make logs service=authservice)
logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f $(filter-out $@,$(MAKECMDGOALS))

## Очистка (остановка + удаление volumes)
clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down -v

## Пересборка всех сервисов
rebuild:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build --force-recreate --no-deps

## Сброс БД (удаление volume SQL Server)
reset-db:
	docker volume rm $$(docker volume ls -q | grep $(SERVICE_SQL)) || true
	@echo "SQL Server volume удален. Перезапустите сервисы через 'make up'."

## Заполнение всех баз данных тестовыми данными
fill-dbs:
	@echo "Заполнение баз данных тестовыми данными..."
	$(PWSH) ./sql/fill_all_databases_in_docker.ps1
	@echo "Готово! Данные успешно заполнены."

## Очистка всех баз данных
clean-dbs:
	@echo "Очистка всех баз данных..."
	$(PWSH) ./sql/clean_all_databases_in_docker.ps1
	@echo "Готово! Базы данных очищены."

## Удаление всех баз данных
drop-dbs:
	@echo "Очистка всех баз данных..."
	$(PWSH) ./sql/drop_all_databases_in_docker.ps1
	@echo "Готово! Базы данных очищены."

## Проверка состояния сервисов
status:
	$(COMPOSE) -f $(COMPOSE_FILE) ps

## Справка
help:
	@echo "Доступные команды:"
	@echo "  up           - Запуск всех сервисов"
	@echo "  up-build     - Запуск всех сервисов с пересборкой"
	@echo "  down         - Остановка всех сервисов"
	@echo "  logs         - Просмотр логов (можно указать сервис: make logs service=nginx-proxy)"
	@echo "  clean        - Полная очистка (сервисы + volumes)"
	@echo "  rebuild      - Пересборка всех сервисов"
	@echo "  reset-db     - Удаление БД SQL Server"
	@echo "  fill-dbs     - Заполнить все БД тестовыми данными"
	@echo "  clean-dbs    - Очистить все БД"
	@echo "  status       - Показать состояние контейнеров"
	@echo "  help         - Вывести эту справку"

# Фикс для передачи аргументов в команды (например, для logs)
%:
	@: