#!/bin/bash
DB_PATH=config/database.yml
DB_TEMPLATE_PATH=config/database.template.yml

function check_env_vars () {
  for name; do
    : ${!name:?$name must not be empty}
  done
}

if [ ! -f $DB_TEMPLATE_PATH ]; then
	echo "Database config not found: please add $DB_TEMPLATE_PATH."
	exit 1
fi
if [ ! -f .env ]; then
	echo 'A .env file must be present.'
	exit 2
fi
if [ ! hash envsubst 2>/dev/null ]; then
	echo 'envsubst not found; please install GNU gettext.'
	exit 3
fi

# Load env vars from .env
set -a
. .env

if ! check_env_vars "RAILS_ENV" "MYSQL_ROOT_PASSWORD" "MYSQL_USER" "MYSQL_PASSWORD" "MYSQL_DATABASE" "SMTP_USERNAME" "SMTP_PASSWORD"; then
	echo 'Some variables are not set in .env, please refer to docker-run.sh for the list'
	exit 4
fi
cat $DB_TEMPLATE_PATH | envsubst > $DB_PATH
echo "Rebuilding Docker container if necessary..."
script/docker-build.sh
echo "Restarting via docker-compose..."
docker-compose restart "$@" # Passes any additional flags
