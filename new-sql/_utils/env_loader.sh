#!/bin/bash

load_env() {
  if [ ! -f ".env" ]; then
    fail ".env file not found in project root"
  fi

  # shellcheck disable=SC2046
  export $(grep -v '^#' .env | xargs) >/dev/null 2>&1

  # Обязательные переменные
  validate_env DB_CONTAINER
  validate_env DB_PASSWORD
}