#!/usr/bin/env bash
#
# Prepares a fresh Arch Linux root shell to run the Ansible playbook:
# installs Ansible, collects the new user's credentials, then hands off.

# 1. exit on error.
# 2. treat unset variables as an error.
# 3. the same as 1., but for pipes.
set -euo pipefail

tags="${1:-all}"
work_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
custom_file="$work_dir/custom.yml"
secret_file="$work_dir/secret.yml"

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "[i] Not running as root, checking sudo access"
    sudo -v
  fi
}

require_arch() {
  if [[ ! -f /etc/os-release ]] || ! grep -q '^ID=arch' /etc/os-release; then
    echo "[!] This script only supports Arch Linux" >&2
    exit 1
  fi
}

install_required_packages() {
  echo "[i] Installing Ansible"
  sudo pacman -Sy --needed --noconfirm ansible
  ansible-galaxy install -r "$work_dir/requirements.yml"
}

welcome_message() {
  echo "Arch Linux bootstrap"
  echo "Press [Ctrl+C] at any time to quit"
  echo
}

prompt_create_new_user() {
  local answer
  while true; do
    read -rp "Create a new user? (no = configure the current user via sudo) [y/N]: " answer
    case "$answer" in
    [yY])
      create_new_user=true
      break
      ;;
    [nN] | "")
      create_new_user=false
      break
      ;;
    *) echo "[!] Invalid selection" ;;
    esac
  done
}

prompt_username() {
  local input
  while true; do
    read -rp "Username for the new user: " input
    if [[ "$input" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      username="$input"
      break
    fi
    echo "[!] Invalid username (lowercase letters, digits, - or _, must not start with a digit)"
  done
}

prompt_password() {
  local pass1 pass2
  while true; do
    read -rsp "Password for $username: " pass1
    echo
    read -rsp "Repeat password: " pass2
    echo
    if [[ -z "$pass1" ]]; then
      echo "[!] Password cannot be empty"
      continue
    fi
    if [[ "$pass1" != "$pass2" ]]; then
      echo "[!] Passwords don't match"
      continue
    fi
    user_password="$pass1"
    break
  done
}

write_vars() {
  : >"$custom_file"
  echo "create_new_user: ${create_new_user}" >>"$custom_file"

  : >"$secret_file"
  chmod 600 "$secret_file"

  if [[ "$create_new_user" == "true" ]]; then
    echo "username: \"${username}\"" >>"$custom_file"
    echo "user_password: \"${user_password}\"" >>"$secret_file"
  fi
}

encrypt_secret() {
  ansible-vault encrypt "$secret_file"
}

run_playbook() {
  echo
  read -rp "Run the playbook now? [y/N]: " answer
  if [[ "$answer" =~ ^[yY]$ ]]; then
    ansible-playbook --ask-vault-pass "$work_dir/bootstrap.yml" --tags "$tags"
    echo
    echo "[i] Done. See README.md for next steps."
  else
    echo "[i] Skipped. Run later with: ansible-playbook bootstrap.yml --tags $tags"
  fi
}

require_root
require_arch
install_required_packages

clear
welcome_message
prompt_create_new_user

if [[ "$create_new_user" == "true" ]]; then
  prompt_username
  prompt_password
fi

write_vars
encrypt_secret

run_playbook
