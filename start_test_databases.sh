#/usr/bin/env bash
docker run --name lobsters_mariadb -p 3306:3306 -e MYSQL_ROOT_PASSWORD=test -e MYSQL_DATABASE=lobsters_test -e MYSQL_USER=test -e MYSQL_PASSWORD=test -d mariadb:10.3-focal
docker run --name lobsters_postgres -p 5432:5432 -e POSTGRES_DB=lobsters_test -e POSTGRES_USER=test -e POSTGRES_PASSWORD=test -d postgres:12-alpine
