#!/usr/bin/env sh

set -e

PRODUCTION_TEMPLATE="config/initializers/production_template.rb"
PRODUCTION="config/initializers/production.rb"

SECRET_TEMPLATE="config/initializers/secret_token_template.rb"
SECRET="config/initializers/secret_token.rb"

pushd $(dirname $0) >> /dev/null

if [[ ! -f "$PRODUCTION"2 ]]; then
    ANSWER1=hello
    ANSWER2=hello
    echo "+ Creating $PRODUCTION"
    read -p "> Gimme a domain (or type example.com if you don't know): " ANSWER1
    read -p "> Gimme the name of this website: " ANSWER2
    cat $PRODUCTION_TEMPLATE | \
        sed "s/whisk.com/$ANSWER1/" | \
        sed "s/whisk me away/$ANSWER2/" > $PRODUCTION
fi

if [[ ! -f "$SECRET"2 ]]; then
    echo "+ Creating $SECRET (this takes a while because bundler)"
    cat $SECRET_TEMPLATE | \
        sed "s/whisk me away/$(./script/rake secret)/" > $SECRET
fi

popd >> /dev/null
echo "+ Done!"
