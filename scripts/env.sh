#!/usr/bin/env bash

#Environments
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ZBX_SERVER_URL="https://localhost:8443"
ZBX_PUBLIC_IP=$(ip route get 1 | awk '{print $NF;exit}')
GRF_SERVER_URL="https://admin:zabbix@localhost:3000"
yesPattern="^[Yy][Ee][Ss]"
HOST_GROUPS=(
"Safous Edge" \
"Safous IDAC"
)