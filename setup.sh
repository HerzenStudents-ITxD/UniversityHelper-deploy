#!/bin/bash

# Проверяем, запущен ли скрипт от имени root
if [ "$EUID" -ne 0 ]; then 
    echo "Скрипт требует прав администратора. Запускаем с повышенными правами..."
    sudo "$0" "$@"
    exit $?
fi

# Функция для проверки наличия команды
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Определяем тип системы
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command_exists make; then
        echo "Make не установлен. Устанавливаем через Homebrew..."
        if ! command_exists brew; then
            echo "Homebrew не установлен. Устанавливаем..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install make
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if ! command_exists make; then
        echo "Make не установлен. Устанавливаем..."
        if command_exists apt-get; then
            apt-get update
            apt-get install -y make
        elif command_exists yum; then
            yum install -y make
        elif command_exists dnf; then
            dnf install -y make
        elif command_exists pacman; then
            pacman -S --noconfirm make
        else
            echo "Не удалось определить пакетный менеджер. Пожалуйста, установите make вручную."
            exit 1
        fi
    fi
else
    echo "Неподдерживаемая операционная система"
    exit 1
fi

# Проверяем наличие make после установки
if command_exists make; then
    echo "Make успешно установлен. Запускаем make..."
    make
else
    echo "Ошибка: Не удалось установить make. Пожалуйста, установите его вручную."
    exit 1
fi 