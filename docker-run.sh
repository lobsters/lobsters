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
. .env
export MYSQL_ROOT_PASSWORD MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE
if ! check_env_vars "MYSQL_ROOT_PASSWORD" "MYSQL_USER" "MYSQL_PASSWORD" "MYSQL_DATABASE"; then 
	echo 'You must set these variables in .env: MYSQL_ROOT_PASSWORD MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE'
	exit 4
fi
cat $DB_TEMPLATE_PATH | envsubst > $DB_PATH
echo "Rebuilding Docker container if necessary..."
./docker-build.sh
echo "Launching docker-compose..."
docker-compose up "$@" # Passes any additional flags
