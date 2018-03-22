#!/bin/sh

# TODO
# This script could use additional logic.

# Install any needed gems. This is useful if you mount
# the project as a volume to /lobsters
bundle install

# Provision Database.
if [ ! -e /var/tmp/first_run_completed ]; then
  echo "Standing up database."
  rake db:setup
  touch /var/tmp/first_run_completed
else
  echo "Running database migrations."
  rake db:migrate
fi

# Set out SECRET_KEY
if [ "$SECRET_KEY" = "" ]; then
  echo "No SECRET_KEY provided, generating one now."
  export SECRET_KEY=$(bundle exec rake secret)
  echo "Your new secret key: $SECRET_KEY"
fi

# Start the rails application.
rails server -b 0.0.0.0 &
pid="$!"
trap "echo 'Stopping Lobsters - pid: $pid'; kill -SIGTERM $pid" SIGINT SIGTERM

# Run the cron job every 5 minutes
while : ; do
  echo "Running cron jobs."
  bundle exec ruby script/mail_new_activity
  bundle exec ruby script/post_to_twitter
  sleep 300
done &

# Wait for process to end.
while kill -0 $pid > /dev/null 2>&1; do
    wait
done
echo "Exiting"
