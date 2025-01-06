# Use the official Ruby image as a base image
FROM ruby:3.3

# Install dependencies
RUN apt-get update -qq && apt-get install -y mariadb-client

# Set an environment variable to avoid installing gem documentation
ENV BUNDLE_PATH /gems

# Set the Rails environment variable
ENV RAILS_ENV development

# Set the working directory inside the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install the gems specified in the Gemfile
RUN bundle install

# Check installed gems and their executables
RUN bundle show rails && bundle exec rails --version

# Copy the rest of the application code into the container
COPY . .


# Expose port 3000 to the outside world
EXPOSE 3000
