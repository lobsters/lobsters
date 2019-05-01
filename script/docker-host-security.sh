#!/bin/bash
set -e # Abort on error
if [ "$DOCKER_CONTENT_TRUST" != "1" ]; then
	echo '$DOCKER_CONTENT_TRUST should be set to 1.'
	echo "If you're using a CLI, add 'export DOCKER_CONTENT_TRUST=1' to .bashrc."
	exit 1;
else
	echo 'Content Trust ok'
fi
rm -rfv log
if [ $(stat -c %a /data/log/) != 777 ]; then
	echo '/data/log/ should have 777 permissions (chmod -R 777 /data/log/).'
	exit 2
else
	echo '/data/log/ permissions ok'
fi
if [ $(stat -c %a /data/sphinx/) != 777 ]; then
	echo '/data/sphinx/ should have 777 permissions (chmod -R 777 /data/sphinx/).'
	exit 2
else
	echo '/data/sphinx/ permissions ok'
fi
mkdir -pv tmp/
chmod -Rv 777 tmp/
mkdir -pv public/assets/
chmod -Rv 777 public/assets/
chmod -v a+rw db/schema.rb
