.PHONY: all check-prerequisites check-docker check-github-desktop start-services check-services check-db check-rabbitmq check-auth check-user check-rights check-community check-feedback check-all

all: check-prerequisites start-services check-services

check-prerequisites: check-docker check-github-desktop

check-docker:
	@echo "Checking if Docker is running..."
	@if [ "$(shell uname)" = "Darwin" ]; then \
		if ! docker info > /dev/null 2>&1; then \
			echo "Docker is not running. Starting Docker Desktop..."; \
			open -a Docker; \
			echo "Waiting for Docker to start..."; \
			while ! docker info > /dev/null 2>&1; do sleep 1; done; \
			echo "Docker is now running!"; \
		else \
			echo "Docker is already running!"; \
		fi \
	elif [ "$(shell uname)" = "Linux" ]; then \
		if ! systemctl is-active --quiet docker; then \
			echo "Docker is not running. Starting Docker..."; \
			sudo systemctl start docker; \
			echo "Waiting for Docker to start..."; \
			while ! systemctl is-active --quiet docker; do sleep 1; done; \
			echo "Docker is now running!"; \
		else \
			echo "Docker is already running!"; \
		fi \
	elif [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		if ! docker info > /dev/null 2>&1; then \
			echo "Docker is not running. Starting Docker Desktop..."; \
			start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"; \
			echo "Waiting for Docker to start..."; \
			while ! docker info > /dev/null 2>&1; do sleep 1; done; \
			echo "Docker is now running!"; \
		else \
			echo "Docker is already running!"; \
		fi \
	else \
		echo "Unsupported operating system"; \
		exit 1; \
	fi

check-github-desktop:
	@echo "Checking if GitHub Desktop is running..."
	@if [ "$(shell uname)" = "Darwin" ]; then \
		if ! pgrep -q "GitHub Desktop"; then \
			echo "GitHub Desktop is not running. Starting GitHub Desktop..."; \
			open -a "GitHub Desktop"; \
			echo "Waiting for GitHub Desktop to start..."; \
			while ! pgrep -q "GitHub Desktop"; do sleep 1; done; \
			echo "GitHub Desktop is now running!"; \
		else \
			echo "GitHub Desktop is already running!"; \
		fi \
	elif [ "$(shell uname)" = "Linux" ]; then \
		if ! pgrep -q "github-desktop"; then \
			echo "GitHub Desktop is not running. Please start it manually."; \
			exit 1; \
		else \
			echo "GitHub Desktop is already running!"; \
		fi \
	elif [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		if ! tasklist | findstr /i "GitHubDesktop.exe" > nul; then \
			echo "GitHub Desktop is not running. Starting GitHub Desktop..."; \
			start "" "%LOCALAPPDATA%\GitHubDesktop\GitHubDesktop.exe"; \
			echo "Waiting for GitHub Desktop to start..."; \
			while ! tasklist | findstr /i "GitHubDesktop.exe" > nul; do sleep 1; done; \
			echo "GitHub Desktop is now running!"; \
		else \
			echo "GitHub Desktop is already running!"; \
		fi \
	else \
		echo "Unsupported operating system"; \
		exit 1; \
	fi

start-services:
	@echo "Starting services..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./setup.ps1; \
	else \
		chmod +x ./setup.sh && ./setup.sh; \
	fi

check-services: check-db check-rabbitmq check-auth check-user check-rights check-community check-feedback

check-db:
	@echo "Checking databases..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		./sql/1_fill_admin_UserDB.bat; \
		./sql/2_fill_admin_RightsDB.bat; \
		./sql/3_fill_admin_CommunityDB.bat; \
		./sql/4_fill_FeedbackDB.bat; \
	else \
		chmod +x ./sql/1_fill_admin_UserDB.sh && ./sql/1_fill_admin_UserDB.sh; \
		chmod +x ./sql/2_fill_admin_RightsDB.sh && ./sql/2_fill_admin_RightsDB.sh; \
		chmod +x ./sql/3_fill_admin_CommunityDB.sh && ./sql/3_fill_admin_CommunityDB.sh; \
		chmod +x ./sql/4_fill_FeedbackDB.sh && ./sql/4_fill_FeedbackDB.sh; \
	fi

check-rabbitmq:
	@echo "Checking RabbitMQ..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./check_rabbitmq.ps1; \
	else \
		chmod +x ./check_rabbitmq.sh && ./check_rabbitmq.sh; \
	fi

check-auth:
	@echo "Checking AuthService..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./check_auth.ps1; \
	else \
		chmod +x ./check_auth.sh && ./check_auth.sh; \
	fi

check-user:
	@echo "Checking UserService..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./check_user.ps1; \
	else \
		chmod +x ./check_user.sh && ./check_user.sh; \
	fi

check-rights:
	@echo "Checking RightsService..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./check_rights.ps1; \
	else \
		chmod +x ./check_rights.sh && ./check_rights.sh; \
	fi

check-community:
	@echo "Checking CommunityService..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./check_community.ps1; \
	else \
		chmod +x ./check_community.sh && ./check_community.sh; \
	fi

check-feedback:
	@echo "Checking FeedbackService..."
	@if [ "$(shell uname)" = "MINGW"* ] || [ "$(shell uname)" = "MSYS"* ]; then \
		powershell -ExecutionPolicy Bypass -File ./check_feedback.ps1; \
	else \
		chmod +x ./check_feedback.sh && ./check_feedback.sh; \
	fi

check-all: check-services