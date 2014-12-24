#!/usr/bin/env sh

set -e

PRODUCTION_TEMPLATE="config/initializer_templates/production.rb"
PRODUCTION="config/initializers/production.rb"

SECRET_TEMPLATE="config/initializer_templates/secret_token.rb"
SECRET="config/initializers/secret_token.rb"

pushd $(dirname $0) >> /dev/null

if [[ ! -f "$PRODUCTION" ]]; then
    ANSWER1=hello
    ANSWER2=hello
    echo "+ Creating $PRODUCTION"
    read -p "> Gimme a domain (type localhost:3000 for development): " ANSWER1
    read -p "> Gimme the name of this website: " ANSWER2
    cat $PRODUCTION_TEMPLATE | \
        sed "s/whisk.com/$ANSWER1/" | \
        sed "s/whisk me away/$ANSWER2/" > $PRODUCTION
fi

if [[ ! -f "$SECRET" ]]; then
    echo "+ Creating $SECRET (this takes a while because bundler)"
    cat $SECRET_TEMPLATE | \
        sed "s/whisk me away/$(./script/rake secret)/" > $SECRET
fi

popd >> /dev/null
echo "+ Done!"
