#!/usr/bin/env bash
# From a MIT-licensed script by guillaumebriday

until bundle exec rake db:version; do
  >&2 echo "Mysql is unavailable - sleeping"
  sleep 1
done

# Provision Database.
db_version=$(bundle exec rake db:version)

if [ "$db_version" = "Current version: 0" ]; then
  bundle exec rake db:schema:load
  bundle exec rake db:migrate
  bundle exec rake db:seed
else
  bundle exec rake db:migrate
fi

# Run ThinkingSphinx rake tasks to configure Sphinx
bundle exec rake ts:index
bundle exec rake ts:start

if [ "$SECRET_KEY_BASE" = "" ]; then
  echo "SECRET_KEY_BASE not set, quitting!"
  exit 2
fi

# Rails leaves the PID file behind when the container is shut down
rm -fv tmp/pids/server.pid

if [ "$RAILS_ENV" = "" ]; then
  echo "RAILS_ENV not set, quitting!"
  exit 1
fi

# Precompile assets
bundle exec rake assets:precompile

# Launch!
unicorn --env $RAILS_ENV
