#!/bin/bash

set -e # Abort on error

function check_env_vars () {
  for name; do
    : ${!name:?$name must not be empty}
  done
}

if [ ! -f .env ]; then
	echo 'A .env file must be present.'
	exit 2
fi

if ! check_env_vars "RAILS_ENV" "SECRET_KEY_BASE" "MYSQL_ROOT_PASSWORD" "MYSQL_USER" "MYSQL_PASSWORD" "MYSQL_DATABASE" "SMTP_USERNAME" "SMTP_PASSWORD"; then
	echo 'Some variables are not set in .env, please refer to script/check-env.sh for the list'
	exit 4
fi
