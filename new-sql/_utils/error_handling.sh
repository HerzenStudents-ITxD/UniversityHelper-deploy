#!/bin/bash

# Цвета для логирования
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

fail() {
  echo -e "${RED}[ERROR] $1${NC}" >&2
  exit 1
}

warn() {
  echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    fail "Dependency $1 not found. Please install it first."
  fi
}

validate_env() {
  if [ -z "${!1}" ]; then
    fail "Environment variable $1 is not set"
  fi
}