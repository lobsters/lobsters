#!/bin/bash
DB_PATH=config/database.yml

if [ ! -f $DB_PATH ]; then
	echo "Database config not found: please add $DB_PATH."
	exit 1
fi
if [ -z $MYSQL_DATABASE ]; then
	echo "Must set the following environment variables: MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD, MYSQL_ROOT_PASSWORD"
	exit 2
fi
if [ -f .env ]; then
	echo 'Do not use .env files.'
	exit 3
fi
sed -i "s/database:.*/database: $MYSQL_DATABASE/g" config/database.yml
sed -i "s/username:.*/username: $MYSQL_USER/g" config/database.yml
sed -i "s/password:.*/password: $MYSQL_PASSWORD/g" config/database.yml
docker-compose up
