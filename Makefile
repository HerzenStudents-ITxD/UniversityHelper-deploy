.PHONY: up down check-db platform-specific

# Default target
all: up check-db platform-specific

# Start all services
up:
	docker compose up -d

# Stop all services
down:
	docker compose down

# Check if SQL Server is ready
check-db:
	@echo "Waiting for SQL Server to be ready..."
	@while ! docker exec sqlserver_db /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "User_1234" -Q "SELECT 1" > /dev/null 2>&1; do \
		echo "SQL Server is not ready yet..."; \
		sleep 5; \
	done
	@echo "SQL Server is ready!"

# Platform-specific tasks
platform-specific:
	@case "$$(uname -s)" in \
		Darwin) \
			echo "Running macOS specific tasks..."; \
			./install_admin_macos.sh; \
			;; \
		Linux) \
			echo "Running Linux specific tasks..."; \
			./install_admin_linux.sh; \
			;; \
		MINGW*|MSYS*|CYGWIN*) \
			echo "Running Windows specific tasks..."; \
			./install_admin_windows.bat; \
			;; \
		*) \
			echo "Unsupported platform"; \
			exit 1; \
			;; \
	esac 