#!/bin/bash
set -e

source /entrypoints/base.sh

main() {

  generate_nginx_conf
  start_nginx
}

generate_https_servers() {
  local prefix="$1" 
}

main "$@"