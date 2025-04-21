.PHONY: up down check-db platform-specific check-prerequisites check-docker check-github-desktop

# Default target
all: check-prerequisites up check-db platform-specific

# Check prerequisites
check-prerequisites: check-docker check-github-desktop

# Check if Docker is running
check-docker:
	@echo "Checking if Docker is running..."
	@if ! docker info > /dev/null 2>&1; then \
		echo "Docker is not running. Starting Docker..."; \
		case "$$(uname -s)" in \
			Darwin) \
				open -a Docker; \
				;; \
			Linux) \
				sudo systemctl start docker; \
				;; \
			MINGW*|MSYS*|CYGWIN*) \
				start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"; \
				;; \
		esac; \
		echo "Waiting for Docker to start..."; \
		while ! docker info > /dev/null 2>&1; do \
			sleep 5; \
		done; \
	fi
	@echo "Docker is running!"

# Check if GitHub Desktop is running
check-github-desktop:
	@echo "Checking if GitHub Desktop is running..."
	@case "$$(uname -s)" in \
		Darwin) \
			if ! pgrep -x "GitHub Desktop" > /dev/null; then \
				echo "GitHub Desktop is not running. Starting GitHub Desktop..."; \
				open -a "GitHub Desktop"; \
				sleep 5; \
			fi; \
			;; \
		Linux) \
			if ! pgrep -x "github-desktop" > /dev/null; then \
				echo "GitHub Desktop is not running. Please start it manually."; \
				exit 1; \
			fi; \
			;; \
		MINGW*|MSYS*|CYGWIN*) \
			if ! tasklist | findstr "GitHubDesktop.exe" > nul; then \
				echo "GitHub Desktop is not running. Starting GitHub Desktop..."; \
				start "" "%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe"; \
				sleep 5; \
			fi; \
			;; \
	esac
	@echo "GitHub Desktop is running!"

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