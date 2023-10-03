# --- Build Stage ---
FROM ruby:3.2.2 as builder

# Install NodeJS, Yarn, and MySQL client (libmysqlclient-dev for mysql2 gem)
RUN apt-get update -qq && apt-get install -y nodejs yarn git libmariadb-dev

# Set the work directory
WORKDIR /lobsters

# Clone the Lobsters repository
RUN git clone https://github.com/lobsters/lobsters.git .

# Install specific version of Bundler
RUN gem install bundler:2.3.16

# Set the bundle path
ENV BUNDLE_PATH=/lobsters/vendor/bundle

# Install the gem dependencies
RUN bundle install

# Copy the database configuration file
COPY config/database.yml config/database.yml

# Precompile assets
RUN bundle exec rake assets:precompile

# --- Application Stage ---
FROM ruby:3.2.2-slim

# Install runtime dependencies for MariaDB and NodeJS
RUN apt-get update && apt-get install -y libmariadb3 nodejs && rm -rf /var/lib/apt/lists/* 

# Set the work directory
WORKDIR /lobsters

# Copy from builder stage
COPY --from=builder /lobsters /lobsters

# Set the bundle path in the application stage
ENV BUNDLE_PATH=/lobsters/vendor/bundle

# Start the application
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]