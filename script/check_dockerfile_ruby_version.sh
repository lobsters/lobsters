#!/bin/sh

# If one instance of the ruby version in .ruby-version is found in Dockerfile.dev
# https://www.gnu.org/software/grep/manual/grep.html
if [ $(grep -cF -f .ruby-version Dockerfile.dev) != 1 ]; then
  # Get ruby image version from Dockerfile.dev
  DOCKERFILE_VERSION=$(grep -oE 'FROM ruby:([0-9\.]+)' Dockerfile.dev)
  RUBY_VERSION=$(cat .ruby-version)
  printf '\033[31mRuby version in .ruby-version, and Dockerfile.dev do not match!\033[0m\n'
  echo ".ruby-version: $RUBY_VERSION"
  echo "Dockerfile.dev: $DOCKERFILE_VERSION"
  echo "Please update the ruby image in Dockerfile.dev to match the .ruby-version file."
  exit 1
fi
printf '\033[32mruby version in .ruby-version and Dockerfile.dev match!\033[0m\n'
